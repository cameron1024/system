use std::time::Duration;
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
use gpui::div;
use gpui::prelude::*;
use gpui::px;

use crate::animated_icon::Icon;
use crate::animated_icon::static_icon;
use crate::bar_module::Module;
use crate::bar_module::bar_module;
use crate::battery_indicator::BatteryIndicator;
use crate::profile_icon::ProfileIcon;
use crate::shell::Sources;
use crate::theme;
use crate::volume_button::VolumeButton;

pub const HEIGHT: f32 = 32.;
const SLIDE_DURATION: Duration = Duration::from_millis(100);

struct Slide {
    started: Instant,
    from: f32,
    to: f32,
}

impl Slide {
    fn progress(&self, now: Instant) -> f32 {
        let t =
            (now.duration_since(self.started).as_secs_f32() / SLIDE_DURATION.as_secs_f32()).min(1.);
        // Exponential ease-out: sharp initial movement, then a short settling tail.
        let eased = if t == 1. { 1. } else { 1. - (-10. * t).exp2() };
        self.from + (self.to - self.from) * eased
    }
}

pub struct Bar {
    sources: Sources,
    profile_icon: Entity<ProfileIcon>,
    volume_button: Entity<VolumeButton>,
    battery: Entity<BatteryIndicator>,
    actions: mpsc::UnboundedSender<ModuleAction>,
    scroll_remainder: f32,
    visible: bool,
    peek_module: Option<Module>,
    slide: Option<Slide>,
    reserved_space: i32,
}

pub enum ModuleAction {
    Click(Module),
    Adjust(Module, i32),
}

impl Bar {
    pub fn set_visible(&mut self, visible: bool, window: &mut Window, cx: &mut Context<Self>) {
        if self.peek_module.take().is_some() {
            cx.notify();
        }
        self.animate_visibility(visible, window, cx);
    }

    pub fn peek(&mut self, module: Module, window: &mut Window, cx: &mut Context<Self>) {
        if self.peek_module != Some(module) {
            self.peek_module = Some(module);
            cx.notify();
        }
        self.animate_visibility(true, window, cx);
    }

    pub fn hide_peek(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        if self.peek_module.is_some() {
            self.animate_visibility(false, window, cx);
        }
    }

    fn animate_visibility(&mut self, visible: bool, window: &mut Window, cx: &mut Context<Self>) {
        if self.visible == visible {
            return;
        }
        let now = Instant::now();
        let from = self.progress(now);
        self.visible = visible;
        self.slide = (!cx.reduce_motion()).then_some(Slide {
            started: now,
            from,
            to: if visible { 1. } else { 0. },
        });
        self.scroll_remainder = 0.;
        // Until the next frame, neither stale nor newly revealed content accepts clicks.
        window.set_input_region(Some(&[]));

        // Keep the surface and drawable full-sized: visibility never reconfigures the GPU.
        cx.notify();
    }

    fn progress(&self, now: Instant) -> f32 {
        self.slide
            .as_ref()
            .map_or(if self.visible { 1. } else { 0. }, |slide| {
                slide.progress(now)
            })
    }

    pub fn new(
        sources: Sources,
        actions: mpsc::UnboundedSender<ModuleAction>,
        cx: &mut Context<Self>,
    ) -> Self {
        // Modules without their own view are rendered inline from these sources.
        redraw_on(&sources.clock, cx);
        redraw_on(&sources.system, cx);
        redraw_on(&sources.brightness, cx);
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
            visible: true,
            peek_module: None,
            slide: None,
            reserved_space: HEIGHT as i32,
        }
    }

    /// While peeking, other modules keep their layout space so the peeked one doesn't move.
    fn module(&self, module: Module, content: impl IntoElement, accent: Rgba) -> Stateful<Div> {
        bar_module(module.name(), content, accent)
            .flex_shrink_0()
            .when(
                self.peek_module.is_some_and(|peek| peek != module),
                |element| element.invisible(),
            )
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
        if this.visible {
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
        if cx.reduce_motion()
            || self
                .slide
                .as_ref()
                .is_some_and(|slide| now.duration_since(slide.started) >= SLIDE_DURATION)
        {
            self.slide = None;
        }
        let progress = self.progress(now);
        // Layer-shell exclusive zones are integer logical pixels. Avoid redundant commits
        // during the easing tail; the surface and GPU drawable remain full-sized.
        let reserved_space = if self.peek_module.is_some() {
            0
        } else {
            (HEIGHT * progress).round() as i32
        };
        if self.reserved_space != reserved_space {
            window.set_exclusive_zone(px(reserved_space as f32));
            self.reserved_space = reserved_space;
        }
        let input = gpui::Bounds {
            origin: gpui::point(px(0.), px(0.)),
            size: gpui::size(window.viewport_size().width, px(HEIGHT * progress)),
        };
        window.set_input_region(Some(if self.visible && self.peek_module.is_none() {
            std::slice::from_ref(&input)
        } else {
            &[]
        }));
        if self.slide.is_some() {
            window.request_animation_frame();
        } else if !self.visible {
            return div().size_full().into_any_element();
        }
        // Detaching the builder cancels GPUI's pending and visible tooltip state on leave.
        // Its default tooltip hit test otherwise uses the stale last in-window position.
        let tooltips_enabled =
            window.is_window_hovered() && self.visible && self.peek_module.is_none();
        let sources = &self.sources;
        let clock = (sources.clock.read(cx).state.target.clone()).unwrap_or_else(|| "--:--".into());
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
        let separator = || {
            div()
                .w(px(1.))
                .h(px(14.))
                .bg(theme::SYSTEM_ACCENT.opacity(0.35))
        };
        let system = div()
            .flex()
            .items_center()
            .gap_2()
            .child(labelled(Icon::Cpu, cpu.1, cpu.0))
            .child(separator())
            .child(labelled(Icon::Memory, memory.1, memory.0))
            .child(separator())
            .child(labelled(Icon::Disk, disk.1, disk.0));

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
        let system = self.module(Module::System, system, theme::SYSTEM_ACCENT);
        let clock = self.module(Module::Clock, clock, theme::CLOCK_ACCENT);
        let brightness = self.module(
            Module::Brightness,
            labelled(Icon::Sun, theme::BRIGHTNESS_ACCENT, brightness),
            theme::BRIGHTNESS_ACCENT,
        );
        let battery = self.module(Module::Battery, self.battery.clone(), theme::BATTERY_ACCENT);

        let profile = Self::clickable(profile, Module::PowerProfile, cx);
        let volume = Self::clickable(volume, Module::Volume, cx);
        let volume = Self::adjustable(volume, Module::Volume, cx);
        let brightness = Self::clickable(brightness, Module::Brightness, cx);
        let brightness = Self::adjustable(brightness, Module::Brightness, cx);

        // Equal-basis sides keep the clock at the display's centre, whatever their contents.
        let side = || div().flex_1().flex().items_center().gap_2();
        let content = div()
            .absolute()
            .top(px(-HEIGHT * (1. - progress)))
            .w_full()
            .h(px(HEIGHT))
            .flex()
            .items_center()
            .gap_2()
            .px_3()
            .text_color(theme::FOREGROUND)
            .font_family("Josefin Sans")
            .text_size(px(14.))
            .when(self.peek_module.is_none(), |content| {
                content.bg(theme::BACKGROUND)
            })
            .child(side().child(profile).child(system))
            .child(clock)
            .child(
                side()
                    .justify_end()
                    .child(brightness)
                    .child(battery)
                    .child(volume),
            );
        div()
            .size_full()
            .relative()
            .overflow_hidden()
            .child(content)
            .into_any_element()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn slide_timing_and_reversal_are_continuous() {
        let start = Instant::now();
        let slide = Slide {
            started: start,
            from: 0.,
            to: 1.,
        };
        assert_eq!(slide.progress(start), 0.);
        assert_eq!(slide.progress(start + SLIDE_DURATION / 2), 0.96875);
        assert_eq!(slide.progress(start + SLIDE_DURATION), 1.);
        assert_eq!(slide.progress(start + SLIDE_DURATION * 2), 1.);

        let reversed_at = start + Duration::from_millis(100);
        let from = slide.progress(reversed_at);
        let reverse = Slide {
            started: reversed_at,
            from,
            to: 0.,
        };
        assert_eq!(reverse.progress(reversed_at), from);
        assert_eq!(reverse.progress(reversed_at + SLIDE_DURATION), 0.);
    }
}
