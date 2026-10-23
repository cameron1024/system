use std::time::Duration;
use std::time::Instant;

use futures::channel::mpsc;

use gpui::Context;
use gpui::Entity;
use gpui::IntoElement;
use gpui::Render;

use gpui::Window;
use gpui::div;
use gpui::prelude::*;
use gpui::px;

use crate::bar_module::Module;
use crate::bar_module::bar_module;

use crate::data_source::Data;

use crate::data_source::clock::Clock;
use crate::data_source::power_profile::PowerProfile;
use crate::data_source::volume::Volume;
use crate::profile_icon::ProfileIcon;
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
    clock: Entity<Data<Clock>>,
    profile_icon: Entity<ProfileIcon>,
    volume_button: Entity<VolumeButton>,
    actions: mpsc::UnboundedSender<ModuleAction>,
    scroll_remainder: f32,
    visible: bool,
    peek_module: Option<Module>,
    slide: Option<Slide>,
    reserved_space: i32,
}

pub enum ModuleAction {
    Click(Module),
    Volume(i32),
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
        clock: Entity<Data<Clock>>,
        power_profile: Entity<Data<PowerProfile>>,
        volume: Entity<Data<Volume>>,
        actions: mpsc::UnboundedSender<ModuleAction>,
        cx: &mut Context<Self>,
    ) -> Self {
        cx.observe(&clock, |this, _, cx| {
            if this.visible {
                cx.notify();
            }
        })
        .detach();
        let profile_icon = cx.new(|cx| ProfileIcon::new(power_profile, cx));
        let volume_button = cx.new(|cx| VolumeButton::new(volume, cx));

        Self {
            clock,
            profile_icon,
            volume_button,
            actions,
            scroll_remainder: 0.,
            visible: true,
            peek_module: None,
            slide: None,
            reserved_space: HEIGHT as i32,
        }
    }
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
        let profile = self.profile_icon.clone();
        let volume = self.volume_button.clone();
        // Detaching the builder cancels GPUI's pending and visible tooltip state on leave.
        // Its default tooltip hit test otherwise uses the stale last in-window position.
        let tooltips_enabled =
            window.is_window_hovered() && self.visible && self.peek_module.is_none();
        let clock = self
            .clock
            .read(cx)
            .state
            .target
            .clone()
            .unwrap_or_else(|| "--:--".into());

        // Content-sized groups, with flexible spacers taking the remaining width.
        let content = div()
            .absolute()
            .top(px(-HEIGHT * (1. - progress)))
            .w_full()
            .h(px(HEIGHT))
            .flex()
            .items_center()
            .px_3()
            .text_color(theme::FOREGROUND)
            .font_family("Josefin Sans")
            .text_size(px(14.));
        let content = if let Some(module) = self.peek_module {
            match module {
                Module::Clock => {
                    content
                        .justify_center()
                        .child(bar_module("clock", clock, theme::CLOCK_ACCENT))
                }
                Module::PowerProfile => content.justify_start().child(bar_module(
                    "power-profile",
                    profile,
                    theme::POWER_ACCENT,
                )),
                Module::Volume => {
                    content
                        .justify_end()
                        .child(bar_module("volume", volume, theme::VOLUME_ACCENT))
                }
            }
        } else {
            content
                .bg(theme::BACKGROUND)
                .child(
                    div().flex().flex_shrink_0().child(
                        bar_module("power-profile", profile, theme::POWER_ACCENT)
                            .when(tooltips_enabled, |button| {
                                // Keep the popup alive through clicks while its button stays hovered.
                                button.hoverable_tooltip({
                                    let icon = self.profile_icon.clone();
                                    move |window, cx| ProfileIcon::tooltip(&icon, window, cx)
                                })
                            })
                            .cursor_pointer()
                            .on_click(cx.listener(|this, _, _, _| {
                                let _ = this
                                    .actions
                                    .unbounded_send(ModuleAction::Click(Module::PowerProfile));
                            })),
                    ),
                )
                .child(div().flex_1())
                .child(bar_module("clock", clock, theme::CLOCK_ACCENT).flex_shrink_0())
                .child(div().flex_1())
                .child(
                    div().flex().flex_shrink_0().justify_end().child(
                        bar_module("volume", volume, theme::VOLUME_ACCENT)
                            .when(tooltips_enabled, |button| {
                                button.hoverable_tooltip({
                                    let volume = self.volume_button.clone();
                                    move |window, cx| VolumeButton::tooltip(&volume, window, cx)
                                })
                            })
                            .cursor_pointer()
                            .on_click(cx.listener(|this, _, _, _| {
                                let _ = this
                                    .actions
                                    .unbounded_send(ModuleAction::Click(Module::Volume));
                            }))
                            .on_scroll_wheel(cx.listener(
                                |this, event: &gpui::ScrollWheelEvent, _, cx| {
                                    // Accumulate smooth touchpad deltas; one line/notch is a 5% step.
                                    this.scroll_remainder +=
                                        f32::from(event.delta.pixel_delta(px(24.)).y) / 24.;
                                    let steps = this.scroll_remainder.trunc() as i32;
                                    this.scroll_remainder -= steps as f32;
                                    if steps != 0 {
                                        let _ = this
                                            .actions
                                            .unbounded_send(ModuleAction::Volume(steps));
                                    }
                                    cx.stop_propagation();
                                },
                            )),
                    ),
                )
        };
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
