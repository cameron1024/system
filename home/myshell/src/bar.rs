use std::cell::RefCell;
use std::rc::Rc;
use std::time::Instant;

use futures::channel::mpsc;

use gpui::Context;
use gpui::Div;
use gpui::Entity;
use gpui::IntoElement;

use gpui::Render;
use gpui::Rgba;
use gpui::ScrollWheelEvent;
use gpui::Stateful;
use gpui::Window;
use gpui::canvas;
use gpui::div;
use gpui::prelude::*;
use gpui::px;
use gpui::rems;

use crate::animated_icon::Icon;
use crate::animated_icon::static_icon;
use crate::bar_module::Module;
use crate::bar_module::bar_module;
use crate::battery_indicator::BatteryIndicator;
use crate::blur::Blur;
use crate::data_source::Data;
use crate::data_source::DataSource;
use crate::liquid;
use crate::profile_icon::ProfileIcon;
use crate::reveal::Reveal;
use crate::scaled::scaled;
use crate::shell::Sources;
use crate::theme;
use crate::tooltip::text_tooltip;

type TooltipBuilder = Box<dyn Fn(&mut Window, &mut gpui::App) -> gpui::AnyView>;
use crate::volume_button::VolumeButton;

pub const HEIGHT: f32 = 36.;
/// Space between a section's (or peeked module's) edge and the liquid around it at rest.
const BLOB_PAD_X: f32 = 12.;
/// Keeps the outer sections' flares on screen at rest.
const EDGE_MARGIN: f32 = BLOB_PAD_X + liquid::FLARE + 2.;
/// A revealing body starts at this fraction of its width, and widens as it drops.
const START_WIDTH: f32 = 0.4;
/// Content scales in from this size as it fades in.
const START_SCALE: f32 = 0.9;

/// A body of liquid behind some content, `progress` of the way through being revealed.
#[derive(Clone, Copy)]
struct Body {
    left: f32,
    right: f32,
    progress: f32,
}

/// While revealing, a body starts narrow and bump-shaped (each side's flare and rounded bottom
/// are equal quarter-ellipses, approximating a cosine), then widens and morphs into its resting
/// shape as it drops.
fn blob(body: Body) -> Option<liquid::Outline> {
    let progress = body.progress.clamp(0., 1.);
    let bottom = HEIGHT * progress;
    let centre = (body.left + body.right) / 2.;
    let rest_half = (body.right - body.left) / 2. + BLOB_PAD_X;
    let half = rest_half * (START_WIDTH + (1. - START_WIDTH) * progress);
    // From the bump (at 0) to the resting shape (at 1).
    let morph = |bump: f32, rest: f32| bump + (rest - bump) * progress;
    let flare_x = morph(half, liquid::FLARE);
    let flare_y = morph(bottom / 2., liquid::FLARE.min(bottom / 2.));
    let radius_y = bottom / 2.;
    // A cosine's steepest run per unit of drop is 2 * width / (pi * height). Easing it to
    // vertical as the body settles gives the resting shape's straight sides.
    let slope = 2. * (flare_x + half) / (std::f32::consts::PI * bottom) * (1. - progress);
    let inset = slope * (bottom - radius_y - flare_y);
    liquid::outline(
        centre - half,
        centre + half,
        bottom,
        liquid::Corners {
            flare_x,
            flare_y,
            radius_x: morph(half, HEIGHT / 2.).min(half - inset).max(0.),
            radius_y,
            slope,
        },
    )
}

/// How far the content row is slid up out of view.
fn slide_offset(progress: f32) -> f32 {
    -HEIGHT * (1. - progress)
}

pub struct Bar {
    sources: Sources,
    profile_icon: Entity<ProfileIcon>,
    volume_button: Entity<VolumeButton>,
    battery: Entity<BatteryIndicator>,
    actions: mpsc::UnboundedSender<ModuleAction>,
    scroll_remainder: f32,
    bar: Reveal,
    /// Modules shown on their own while the bar is hidden, each with its own animation.
    peeks: Vec<(Module, Reveal)>,
    /// The bar's and each peek's progress for the frame being rendered.
    bar_progress: f32,
    peek_progress: Vec<(Module, f32)>,
    /// Written by each section (or peeked module) during prepaint, then read when painting
    /// the liquid behind them.
    liquid: Rc<RefCell<Vec<Body>>>,
    /// Blur behind the liquid, if the compositor supports it. Created on the first frame.
    blur: Option<Rc<RefCell<Option<Blur>>>>,
    reserved_space: i32,
}

pub enum ModuleAction {
    Click(Module),
    Adjust(Module, i32),
}

impl Bar {
    pub fn set_visible(&mut self, visible: bool, window: &mut Window, cx: &mut Context<Self>) {
        // The full bar includes every module, so it replaces any peeks.
        self.peeks.clear();
        let (reduce_motion, now) = (cx.reduce_motion(), Instant::now());
        if self.bar.set(visible, reduce_motion, now) {
            self.scroll_remainder = 0.;
            // Until the next frame, neither stale nor newly revealed content accepts clicks.
            window.set_input_region(Some(&[]));
        }
        cx.notify();
    }

    pub fn peek(&mut self, module: Module, cx: &mut Context<Self>) {
        let (reduce_motion, now) = (cx.reduce_motion(), Instant::now());
        match self.peeks.iter_mut().find(|(peeked, _)| *peeked == module) {
            Some((_, reveal)) => {
                reveal.set(true, reduce_motion, now);
            }
            None => {
                let mut reveal = Reveal::new(false, now);
                reveal.set(true, reduce_motion, now);
                self.peeks.push((module, reveal));
            }
        }
        cx.notify();
    }

    pub fn hide_peek(&mut self, module: Module, cx: &mut Context<Self>) {
        let reduce_motion = cx.reduce_motion();
        if let Some((_, reveal)) = self.peeks.iter_mut().find(|(peeked, _)| *peeked == module) {
            reveal.set(false, reduce_motion, Instant::now());
            cx.notify();
        }
    }

    /// Whether anything is on screen, including animations.
    fn shown(&self) -> bool {
        !self.bar.hidden() || !self.peeks.is_empty()
    }

    pub fn new(
        sources: Sources,
        actions: mpsc::UnboundedSender<ModuleAction>,
        cx: &mut Context<Self>,
    ) -> Self {
        // Modules without their own view are rendered inline from these sources.
        redraw_on(&sources.clock, cx);
        redraw_on(&sources.system, cx); // CPU, memory and disk
        redraw_on(&sources.brightness, cx);
        redraw_on(&sources.caffeine, cx);
        let power = sources.power.clone();
        let volume = sources.volume.clone();
        let battery = sources.battery.clone();

        Self {
            sources,
            profile_icon: cx.new(|cx| ProfileIcon::new(power, cx)),
            volume_button: cx.new(|cx| VolumeButton::new(volume, cx)),
            battery: cx.new(|cx| BatteryIndicator::new(battery, cx)),
            actions,
            scroll_remainder: 0.,
            bar: Reveal::new(true, Instant::now()),
            peeks: Vec::new(),
            bar_progress: 1.,
            peek_progress: Vec::new(),
            liquid: Rc::default(),
            blur: None,
            reserved_space: HEIGHT as i32,
        }
    }

    /// Content fades and scales in as it's revealed. While peeking, other modules keep their
    /// layout space so the peeked one doesn't move.
    fn module(&self, module: Module, content: impl IntoElement, accent: Rgba) -> Stateful<Div> {
        let peeked = (self.peek_progress.iter()).find(|(peeked, _)| *peeked == module);
        let progress = match peeked {
            _ if !self.bar.hidden() => self.bar_progress,
            Some(&(_, progress)) => progress,
            None => 0.,
        };
        let scale = START_SCALE + (1. - START_SCALE) * progress;
        let element = bar_module(module.name(), scaled(scale, content), accent)
            .flex_shrink_0()
            .opacity(progress);
        match peeked {
            _ if !self.bar.hidden() => element,
            // Offset visually only, so neighbours never move.
            Some(&(_, progress)) => element
                .relative()
                .top(px(slide_offset(progress)))
                .child(self.liquid_anchor(progress)),
            None => element.invisible(),
        }
    }

    /// A group of modules with separators between them, sharing one body of liquid unless
    /// modules are peeking.
    fn section<const N: usize>(&self, modules: [Stateful<Div>; N]) -> Div {
        let peeking = self.bar.hidden();
        let mut section = div()
            .flex()
            .items_center()
            .gap_1()
            .when(!peeking, |section| {
                section.child(self.liquid_anchor(self.bar_progress))
            });
        for (index, module) in modules.into_iter().enumerate() {
            if index > 0 {
                // Kept in layout while peeking, so peeked modules don't move.
                section = section.child(
                    div()
                        .w(px(1.))
                        .h(px(14.))
                        .flex_shrink_0()
                        .bg(theme::SEPARATOR)
                        .opacity(self.bar_progress)
                        .when(peeking, |separator| separator.invisible()),
                );
            }
            section = section.child(module);
        }
        section
    }

    /// Records its parent's horizontal bounds, so a body `progress` of the way through being
    /// revealed can be painted behind it.
    fn liquid_anchor(&self, progress: f32) -> impl IntoElement {
        let liquid = self.liquid.clone();
        canvas(
            move |bounds, _, _| {
                liquid.borrow_mut().push(Body {
                    left: f32::from(bounds.left()),
                    right: f32::from(bounds.right()),
                    progress,
                })
            },
            |_, _, _, _| {},
        )
        .absolute()
        .inset_0()
    }

    fn clickable(element: Stateful<Div>, module: Module, cx: &mut Context<Self>) -> Stateful<Div> {
        element
            .cursor_pointer()
            .on_click(cx.listener(move |this, _, _, _| {
                let _ = this.actions.unbounded_send(ModuleAction::Click(module));
            }))
    }

    fn adjustable(element: Stateful<Div>, module: Module, cx: &mut Context<Self>) -> Stateful<Div> {
        element.on_scroll_wheel(cx.listener(move |this, event: &ScrollWheelEvent, _, cx| {
            // Accumulate smooth touchpad deltas; one line/notch is one step.
            this.scroll_remainder += f32::from(event.delta.pixel_delta(px(24.)).y) / 24.;
            let steps = this.scroll_remainder.trunc() as i32;
            this.scroll_remainder -= steps as f32;
            if steps != 0 {
                let _ = this
                    .actions
                    .unbounded_send(ModuleAction::Adjust(module, steps));
            }
            cx.stop_propagation();
        }))
    }
}

fn redraw_on<T: 'static>(entity: &Entity<T>, cx: &mut Context<Bar>) {
    cx.observe(entity, |this, _, cx| {
        if this.shown() {
            cx.notify();
        }
    })
    .detach();
}

fn labelled(icon: Icon, color: Rgba, label: String) -> Div {
    div()
        .flex()
        .items_center()
        .gap_1()
        .text_color(color)
        .child(static_icon(icon, color))
        .child(label)
}

impl Render for Bar {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let now = Instant::now();
        self.bar.settle(now);
        for (_, reveal) in &mut self.peeks {
            reveal.settle(now);
        }
        self.peeks.retain(|(_, reveal)| !reveal.hidden());
        self.peek_progress = (self.peeks.iter())
            .map(|(module, reveal)| (*module, reveal.progress(now)))
            .collect();
        self.bar_progress = self.bar.progress(now);

        // Layer-shell exclusive zones are whole logical pixels, so this only commits when the
        // rounded height changes.
        let reserved_space = (HEIGHT * self.bar_progress).round() as i32;
        if self.reserved_space != reserved_space {
            window.set_exclusive_zone(px(reserved_space as f32));
            self.reserved_space = reserved_space;
        }
        let input = gpui::Bounds {
            origin: gpui::point(px(0.), px(0.)),
            size: gpui::size(window.viewport_size().width, px(HEIGHT)),
        };
        window.set_input_region(Some(if self.bar.visible {
            std::slice::from_ref(&input)
        } else {
            &[]
        }));
        if self.bar.animating() || self.peeks.iter().any(|(_, reveal)| reveal.animating()) {
            window.request_animation_frame();
        }
        let blur = (self.blur)
            .get_or_insert_with(|| Rc::new(RefCell::new(Blur::new(window))))
            .clone();
        if !self.shown() {
            if let Some(blur) = blur.borrow_mut().as_mut() {
                blur.set_region(Vec::new());
            }
            return div().size_full().into_any_element();
        }
        // Detaching the builder cancels GPUI's pending and visible tooltip state on leave.
        // Its default tooltip hit test otherwise uses the stale last in-window position.
        let tooltips_enabled = window.is_window_hovered() && self.bar.visible;
        let sources = &self.sources;
        let clock = (sources.clock.read(cx).state.target.as_ref())
            .map_or_else(|| "--:--".into(), |clock| clock.time.clone());
        let tooltip = |element: Stateful<Div>, tooltip: TooltipBuilder| {
            element.when(tooltips_enabled, |element| {
                element.hoverable_tooltip(tooltip)
            })
        };
        // Labels for tooltips, from each source's latest value.
        fn label<S: DataSource>(data: &Data<S>, label: impl Fn(&S::Value) -> String) -> String {
            data.state.target.as_ref().map_or_else(|| "…".into(), label)
        }
        // Coloured by usage; the disk shows free space but is coloured by used space.
        let [cpu, memory, disk] = sources.system.read(cx).state.target.as_ref().map_or_else(
            || ["--%", "--%", "--"].map(|label| (label.to_owned(), theme::SYSTEM_ACCENT)),
            |stats| {
                [
                    (format!("{}%", stats.cpu), theme::usage(stats.cpu)),
                    (format!("{}%", stats.memory), theme::usage(stats.memory)),
                    (stats.disk_free_label(), theme::usage(stats.disk)),
                ]
            },
        );
        let brightness = sources
            .brightness
            .read(cx)
            .state
            .target
            .as_ref()
            .map_or_else(
                || "--%".into(),
                |brightness| format!("{}%", brightness.percent),
            );

        let profile = self
            .module(
                Module::PowerProfile,
                self.profile_icon.clone(),
                theme::POWER_ACCENT,
            )
            .when(tooltips_enabled, |button| {
                // Keep the popup alive through clicks while its button stays hovered.
                button.hoverable_tooltip({
                    let icon = self.profile_icon.clone();
                    move |window, cx| ProfileIcon::tooltip(&icon, window, cx)
                })
            });
        let volume = self
            .module(
                Module::Volume,
                self.volume_button.clone(),
                theme::VOLUME_ACCENT,
            )
            .when(tooltips_enabled, |button| {
                button.hoverable_tooltip({
                    let volume = self.volume_button.clone();
                    move |window, cx| VolumeButton::tooltip(&volume, window, cx)
                })
            });
        let [cpu, memory, disk] = [
            (Module::Cpu, Icon::Cpu, cpu),
            (Module::Memory, Icon::Memory, memory),
            (Module::Disk, Icon::Disk, disk),
        ]
        .map(|(module, icon, (label, color))| {
            self.module(module, labelled(icon, color, label), color)
        });
        let cpu = tooltip(
            cpu,
            Box::new(text_tooltip(
                &sources.system,
                theme::SYSTEM_ACCENT,
                |data| label(data, |stats| stats.cpu_temperature_label()),
            )),
        );
        let memory = tooltip(
            memory,
            Box::new(text_tooltip(
                &sources.system,
                theme::SYSTEM_ACCENT,
                |data| label(data, |stats| stats.memory_label()),
            )),
        );
        let clock = tooltip(
            self.module(Module::Clock, clock, theme::CLOCK_ACCENT),
            Box::new(text_tooltip(&sources.clock, theme::CLOCK_ACCENT, |data| {
                label(data, |clock| clock.date.clone())
            })),
        );
        let brightness = tooltip(
            self.module(
                Module::Brightness,
                labelled(Icon::Sun, theme::BRIGHTNESS_ACCENT, brightness),
                theme::BRIGHTNESS_ACCENT,
            ),
            Box::new(text_tooltip(
                &sources.brightness,
                theme::BRIGHTNESS_ACCENT,
                |data| label(data, |brightness| brightness.display.clone()),
            )),
        );
        let battery = tooltip(
            self.module(Module::Battery, self.battery.clone(), theme::BATTERY_ACCENT),
            Box::new(text_tooltip(
                &sources.battery,
                theme::BATTERY_ACCENT,
                |data| label(data, |battery| battery.time_label()),
            )),
        );

        let profile = Self::clickable(profile, Module::PowerProfile, cx);
        let volume = Self::clickable(volume, Module::Volume, cx);
        let volume = Self::adjustable(volume, Module::Volume, cx);
        // Muted while off, so it reads as a toggle.
        let caffeine_color = if sources.caffeine.read(cx).active {
            theme::CAFFEINE_ACCENT
        } else {
            theme::MUTED
        };
        let caffeine = self.module(
            Module::Caffeine,
            static_icon(Icon::Coffee, caffeine_color),
            caffeine_color,
        );
        let caffeine = tooltip(
            caffeine,
            Box::new(text_tooltip(
                &sources.caffeine,
                theme::CAFFEINE_ACCENT,
                |caffeine| {
                    if caffeine.active {
                        "Caffeine enabled".into()
                    } else {
                        "Caffeine disabled".into()
                    }
                },
            )),
        );
        let caffeine = Self::clickable(caffeine, Module::Caffeine, cx);
        let brightness = Self::clickable(brightness, Module::Brightness, cx);
        let brightness = Self::adjustable(brightness, Module::Brightness, cx);

        let left = self.section([profile, battery, cpu, memory, disk]);
        let center = self.section([clock]);
        let right = self.section([caffeine, brightness, volume]);
        // Equal-basis sides keep the clock at the display's centre, whatever their contents.
        let side = || div().flex_1().flex().items_center();
        // While peeking, the row stays put and each peeked module is offset on its own.
        let offset = if self.bar.hidden() {
            0.
        } else {
            slide_offset(self.bar_progress)
        };
        let content = div()
            .absolute()
            .top(px(offset))
            .w_full()
            .h(px(HEIGHT))
            .flex()
            .items_center()
            .gap_2()
            .px(px(EDGE_MARGIN))
            .text_color(theme::FOREGROUND)
            .font_family("Josefin Sans")
            // Rem-based, so `scaled` can scale it.
            .text_size(rems(1.))
            .child(side().child(left))
            .child(center)
            .child(side().justify_end().child(right));
        self.liquid.borrow_mut().clear();
        let liquid = self.liquid.clone();
        div()
            .size_full()
            .relative()
            .overflow_hidden()
            // Painted first, so it sits behind the content whose bounds it follows.
            .child(
                canvas(
                    |_, _, _| {},
                    move |_, _, window, _| {
                        let outlines: Vec<_> =
                            liquid.borrow().iter().copied().filter_map(blob).collect();
                        if let Some(path) = liquid::path(&outlines) {
                            window.paint_path(path, theme::BACKGROUND);
                        }
                        if let Some(blur) = blur.borrow_mut().as_mut() {
                            blur.set_region(liquid::rows(&outlines));
                        }
                    },
                )
                .absolute()
                .inset_0(),
            )
            .child(content)
            .into_any_element()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn liquid_has_no_sharp_corners_at_any_progress() {
        let mut failures = Vec::new();
        for step in 0..=200 {
            let progress = step as f32 / 200.;
            // Below 6px tall, every curve is a pixel or two across, so even a correct
            // semicircle turns more than the threshold within the 2px window.
            if HEIGHT * progress < 6. {
                continue;
            }
            for width in [20., 400.] {
                let body = Body {
                    left: 100.,
                    right: 100. + width,
                    progress,
                };
                let Some(outline) = blob(body) else {
                    continue;
                };
                let corners = liquid::tests::sharp_corners(&outline, 2., 60.);
                if let Some(worst) = corners.iter().max_by(|a, b| a.0.total_cmp(&b.0)) {
                    failures.push(format!(
                        "width {width}, progress {progress:.3}: {:.0}° at ({:.1}, {:.1})",
                        worst.0, worst.1.0, worst.1.1
                    ));
                }
            }
        }
        assert!(failures.is_empty(), "{}", failures.join("\n"));
    }
}
