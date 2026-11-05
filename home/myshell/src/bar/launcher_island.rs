//! The launcher, which the clock grows into like the notifications module into its dropdown: the
//! clock slides to the right of a widening header (the mode selector on its left, and the mode's
//! name in the middle), and a search field and results drop below. While it's open, the bar takes
//! the keyboard.

use gpui::KeyDownEvent;
use gpui::layer_shell::KeyboardInteractivity;

use super::*;
use crate::fade::background;
use crate::fade::tinted;
use crate::launcher::Chosen;
use crate::launcher::Entry;
use crate::launcher::ICON_SIZE;
use crate::launcher::Launcher;
use crate::launcher::Menu;
use crate::launcher::Mode;
use crate::launcher::Motion;
use crate::launcher::VISIBLE;

const WIDTH: f32 = 640.;
const SEARCH_HEIGHT: f32 = 40.;
const RESULT_HEIGHT: f32 = 46.;
/// "Copied", below the clock.
pub(super) const COPIED_HEIGHT: f32 = 20.;

/// Below the clock, at rest: the search field, then `rows` results (or a message).
const fn body_height(rows: f32) -> f32 {
    LIST_PAD / 2. + SEARCH_HEIGHT + LIST_PAD / 2. + rows.max(1.) * RESULT_HEIGHT + LIST_PAD_BOTTOM
}

/// The bar's surface while it's open: tall enough for the most results.
pub(super) const SURFACE_HEIGHT: f32 = HEIGHT + body_height(VISIBLE as f32);

/// The first protrusion: about the clock's liquid, which isn't shown while the bar is hidden.
/// Half its width.
const DRIP_HALF: f32 = 38.;
/// Use the full reveal for the spring's settling tail.
pub(super) const DRIPPED: f32 = 1.;
/// When the protrusion is out, through the drip.
const PROTRUDED: f32 = 0.12;

/// With the bar hidden, the launcher drips down: a clock-sized protrusion, which then widens and
/// deepens into the open launcher. `body.progress` is linear in time.
pub(super) fn drip(body: Body) -> Option<liquid::Outline> {
    let t = (body.progress / DRIPPED).clamp(0., 1.);
    let centre = (body.left + body.right) / 2.;
    let (half, height, progress) = if t < PROTRUDED {
        let x = t / PROTRUDED;
        (DRIP_HALF, HEIGHT, 1. - (1. - x) * (1. - x))
    } else {
        // Stretch out of the small top-edge seed, overshoot, then settle into the full island.
        let u = crate::reveal::island_motion((t - PROTRUDED) / (1. - PROTRUDED));
        let rest_half = (body.right - body.left) / 2. + BLOB_PAD_X;
        let half = DRIP_HALF + (rest_half - DRIP_HALF) * u;
        (half, HEIGHT + (body.height - HEIGHT) * u, 1.)
    };
    blob(Body {
        left: centre - half + BLOB_PAD_X,
        right: centre + half - BLOB_PAD_X,
        height,
        progress,
        drip: false,
        ..body
    })
}

impl Bar {
    pub fn launcher_open(&self) -> bool {
        self.launcher.visible
    }

    /// Opening closes any other group, and rescans apps. The window takes (and later releases)
    /// the keyboard when rendering.
    pub fn set_launcher(&mut self, open: bool, cx: &mut Context<Self>) {
        if !self.launcher.set(open, cx.reduce_motion(), Instant::now()) {
            return;
        }

        if !open {
            (self.sources.launcher).update(cx, |launcher, _| launcher.close());
        }

        if open {
            self.launcher_slides = !self.bar.visible;
            self.set_wifi(false, cx);
            self.close_tray_menu(cx);
            if self.pinned {
                let action = ModuleAction::Notifications(NotificationAction::CloseDropdown);
                let _ = self.actions.unbounded_send(action);
            }
            if self.hover_open {
                self.hover_open = false;
                (self.dropdown).set(self.pinned, cx.reduce_motion(), Instant::now());
            }
            (self.sources.launcher).update(cx, |launcher, cx| launcher.open(None, cx));
        }
        cx.notify();
    }

    /// Opens the launcher (or starts again, if it's open) with `myshell-menu`'s options.
    pub fn open_menu(&mut self, menu: Menu, cx: &mut Context<Self>) {
        self.set_launcher(true, cx);
        (self.sources.launcher).update(cx, |launcher, cx| launcher.open(Some(menu), cx));
    }

    /// The launcher and password take the keyboard; other panels accept it on demand.
    pub(super) fn sync_launcher_window(&mut self, window: &mut Window, cx: &mut App) {
        use KeyboardInteractivity::*;
        let keyboard = if self.launcher.visible || self.wifi_password.is_some() {
            Exclusive
        } else if self.wifi.visible
            || self.tray_reveal.visible
            || self.dropdown.visible
            || self.outside_click.is_some()
        {
            // Keep keyboard access while handing over to an outside-click grab: niri
            // dismisses the popup if its parent loses the keyboard.
            OnDemand
        } else {
            None
        };
        if keyboard != self.launcher_keyboard {
            window.set_keyboard_interactivity(keyboard);
            if keyboard != None {
                if let Some(input) = &self.wifi_password {
                    input.update(cx, |input, cx| input.focus(window, cx));
                } else {
                    self.launcher_focus.focus(window, cx);
                }
            }
        }
        self.launcher_keyboard = keyboard;
    }

    /// Opens once the launcher has, since creating it would stall the animation, and goes as soon
    /// as the launcher starts closing, so presses pass through.
    pub(super) fn sync_backdrop(
        &mut self,
        inset: f32,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) {
        let inset = px(inset);
        match &self.backdrop {
            Some((_, backdrop)) if self.launcher.visible => backdrop.update(cx, |backdrop, cx| {
                if backdrop.inset != inset {
                    backdrop.inset = inset;
                    cx.notify();
                }
            }),
            Some(_) => {
                let (handle, _) = self.backdrop.take().unwrap();
                cx.defer(move |cx| {
                    let _ = handle.update(cx, |_, window, _| window.remove_window());
                });
            }
            None if self.launcher.visible && !self.launcher.animating() => {
                cx.defer_in(window, move |this, window, cx| {
                    if this.backdrop.is_some() || !this.launcher.visible {
                        return;
                    }
                    let bar = cx.entity().downgrade();
                    let close = move |cx: &mut App| {
                        let _ = bar.update(cx, |bar, cx| bar.set_launcher(false, cx));
                    };
                    this.backdrop = crate::backdrop::open(window, inset, close, cx);
                });
            }
            None => {}
        }
    }

    pub(super) fn launcher_key(&mut self, event: &KeyDownEvent, cx: &mut Context<Self>) {
        let keystroke = &event.keystroke;
        let modifiers = keystroke.modifiers;
        let (control, shift) = (modifiers.control, modifiers.shift);
        let launcher = self.sources.launcher.clone();
        let with = |cx: &mut Context<Self>, f: &dyn Fn(&mut Launcher, &mut Context<Launcher>)| {
            launcher.update(cx, |launcher, cx| f(launcher, cx))
        };
        let (back, forward) = if control {
            (Motion::WordLeft, Motion::WordRight)
        } else {
            (Motion::Left, Motion::Right)
        };
        match (keystroke.key.as_str(), control) {
            // Ctrl-Enter copies an emoji, rather than typing it.
            ("enter", copy) => self.launch(None, copy, cx),
            // Ctrl-h/j/k/l are the arrow keys, as in vim.
            ("h", true) => with(cx, &|l, cx| l.move_to(Motion::Left, shift, cx)),
            ("l", true) => with(cx, &|l, cx| l.move_to(Motion::Right, shift, cx)),
            ("up", _) | ("p", true) | ("k", true) => with(cx, &|l, cx| l.select(-1, cx)),
            ("down", _) | ("n", true) | ("j", true) => with(cx, &|l, cx| l.select(1, cx)),
            ("tab", _) => with(cx, &|l, cx| l.cycle_mode(if shift { -1 } else { 1 }, cx)),
            ("left", _) => with(cx, &|l, cx| l.move_to(back, shift, cx)),
            ("right", _) => with(cx, &|l, cx| l.move_to(forward, shift, cx)),
            ("home", _) => with(cx, &|l, cx| l.move_to(Motion::Start, shift, cx)),
            ("end", _) => with(cx, &|l, cx| l.move_to(Motion::End, shift, cx)),
            ("a", true) => with(cx, &|l, cx| l.select_all(cx)),
            ("backspace", _) => with(cx, &|l, cx| l.delete(back, cx)),
            ("delete", _) => with(cx, &|l, cx| l.delete(forward, cx)),
            ("w", true) => with(cx, &|l, cx| l.delete(Motion::WordLeft, cx)),
            ("u", true) => with(cx, &|l, cx| l.delete(Motion::Start, cx)),
            ("c", true) | ("x", true) => {
                let selected = launcher.read(cx).selected_text().to_owned();
                if selected.is_empty() {
                    return;
                }
                cx.write_to_clipboard(gpui::ClipboardItem::new_string(selected));
                if keystroke.key == "x" {
                    with(cx, &|l, cx| l.insert("", cx));
                }
            }
            ("v", true) => {
                let pasted = (cx.read_from_clipboard())
                    .and_then(|item| item.text())
                    .and_then(|text| text.lines().next().map(str::to_owned))
                    .unwrap_or_default();
                with(cx, &|l, cx| l.insert(&pasted, cx));
            }
            _ if !control && !modifiers.alt && !modifiers.platform => {
                let Some(text) = keystroke.key_char.clone() else {
                    return;
                };
                with(cx, &|l, cx| l.insert(&text, cx));
            }
            _ => return,
        }
        cx.stop_propagation();
    }

    /// How far it's grown: with its reveal, or (if it slides down whole) fully, until gone.
    fn launcher_expand(&self) -> f32 {
        match (self.launcher_slides, self.launcher.hidden()) {
            (false, _) => self.launcher_progress,
            (true, hidden) => f32::from(u8::from(!hidden)),
        }
    }

    /// The result at `index`, or else the selected one, then closes.
    fn launch(&mut self, index: Option<usize>, copy: bool, cx: &mut Context<Self>) {
        let chosen =
            (self.sources.launcher).update(cx, |launcher, cx| launcher.choose(index, copy, cx));
        self.set_launcher(false, cx);
        match chosen {
            Some(Chosen::Copied(copied)) => cx
                .spawn(async move |this, cx| {
                    if copied.await {
                        let _ = this.update(cx, |this, cx| this.show_copied(cx));
                    }
                })
                .detach(),
            // Typed once the keyboard is back with the window that had it (see `Bar::new`).
            // Dropped if it never is, rather than typed somewhere unexpected later.
            Some(Chosen::Type(text)) => {
                let expiry = cx.spawn(async |this, cx| {
                    async_io::Timer::after(Duration::from_secs(1)).await;
                    let _ = this.update(cx, |this, _| this.pending_type = None);
                });
                self.pending_type = Some((text, expiry));
            }
            None => {}
        }
    }

    /// Shows "Copied" below the clock for a moment.
    fn show_copied(&mut self, cx: &mut Context<Self>) {
        self.copied.set(true, cx.reduce_motion(), Instant::now());
        self.copied_timer = cx.spawn(async |this, cx| {
            async_io::Timer::after(Duration::from_secs(1)).await;
            let _ = this.update(cx, |this, cx| {
                this.copied.set(false, cx.reduce_motion(), Instant::now());
                cx.notify();
            });
        });
        cx.notify();
    }

    /// The clock module, and the launcher it grows into. With the bar hidden, it shows (sliding
    /// down) while peeked or open, like the notifications module.
    pub(super) fn launcher_island(
        &self,
        time: String,
        tooltips_enabled: bool,
        now: Instant,
        cx: &mut Context<Self>,
    ) -> Stateful<Div> {
        let peek = (self.peek_progress.iter())
            .find(|(module, _)| *module == Module::Clock)
            .map(|&(_, progress)| progress);
        let open = self.launcher_expand();
        let copied = self.copied_progress;
        // Open (or showing "Copied"), it stays in place while the bar shows or hides around it.
        let hold = self.launcher_progress.max(copied);
        let progress = if self.bar.hidden() {
            peek.unwrap_or(0.).max(hold)
        } else {
            self.bar_progress.max(hold)
        };
        let shown = !self.bar.hidden()
            || peek.is_some()
            || !self.launcher.hidden()
            || !self.copied.hidden();
        let scale = START_SCALE + (1. - START_SCALE) * island_motion(progress);
        let expanded = self.launcher.visible;

        let date = expanded
            .then(|| self.sources.clock.read(cx).state.target.as_ref())
            .flatten()
            .map(|clock| (clock.weekday.clone(), clock.numeric_date.clone()));
        let dot = || div().text_color(theme::MUTED).opacity(open).child("·");
        let time = div()
            .flex()
            .items_center()
            .gap_2()
            .when_some(date, |time, (weekday, date)| {
                let muted = |text| div().text_color(theme::MUTED).opacity(open).child(text);
                time.child(muted(weekday))
                    .child(dot())
                    .child(muted(date))
                    .child(dot())
            })
            .child(time);
        let clock = if expanded {
            // Without button or hover decoration: like the rest of the header, it closes it.
            div()
                .id(Module::Clock.name())
                .px_1p5()
                .h(px(crate::bar_module::HEIGHT))
                .flex()
                .flex_shrink_0()
                .items_center()
                .text_color(theme::CLOCK_ACCENT)
                .child(scaled(scale, time))
        } else {
            bar_module(
                Module::Clock.name(),
                scaled(scale, time),
                theme::CLOCK_ACCENT,
                false,
            )
            .flex_shrink_0()
            .when(tooltips_enabled, |clock| {
                clock.hoverable_tooltip(text_tooltip(
                    &self.sources.clock,
                    theme::CLOCK_ACCENT,
                    |data| {
                        (data.state.target.as_ref())
                            .map_or_else(|| "…".into(), |clock| clock.date.clone())
                    },
                ))
            })
            .cursor_pointer()
            .on_click(cx.listener(|this, _, window, _| {
                let action = ModuleAction::ToggleLauncher(window.window_handle());
                let _ = this.actions.unbounded_send(action);
            }))
        };
        // The controls fill the space left of the clock, clipped to it as the header widens.
        // With no width of their own, they never affect the island's. A menu has no modes, but
        // shows its prompt there instead.
        let launcher = self.sources.launcher.read(cx);
        let (mode, _) = launcher.mode();
        let controls = if mode == Mode::Menu {
            (launcher.prompt())
                .map(|prompt| {
                    div()
                        .overflow_hidden()
                        .whitespace_nowrap()
                        .text_ellipsis()
                        .text_color(theme::FOREGROUND)
                        .child(prompt.to_owned())
                })
                .map(IntoElement::into_any_element)
        } else {
            let selector = div().flex().items_center().gap_1().children(
                Mode::SELECTABLE.map(|option| self.launcher_mode(option, option == mode, cx)),
            );
            Some(selector.into_any_element())
        };
        // Anywhere else along the top closes it.
        let header = div()
            .id("launcher-header")
            .relative()
            .flex()
            .min_w(px(WIDTH * island_motion(open)))
            .when(self.launcher.visible, |header| {
                header
                    .cursor_pointer()
                    .on_click(cx.listener(|this, _, _, cx| this.set_launcher(false, cx)))
            })
            .child(
                div()
                    .w_0()
                    .flex_grow(1.)
                    .h(px(crate::bar_module::HEIGHT))
                    .overflow_hidden()
                    .when(self.launcher.visible && open > 0., |slot| {
                        slot.child(
                            div()
                                .size_full()
                                .pl(px(LIST_PAD - 4.))
                                .flex()
                                .items_center()
                                .opacity(open)
                                .children(controls),
                        )
                    }),
            )
            .child(clock);
        let rows = self.launcher_rows.value(now).max(1.);
        // Dripping down, the contents fade in as the drop fills out, rather than sliding.
        let drip = (self.launcher_slides && !self.launcher.hidden()).then(|| {
            let t = self.launcher.linear(now);
            (t, ((t - PROTRUDED) / 0.5).clamp(0., 1.))
        });
        let (opacity, offset) = match drip {
            Some((_, fade)) => (fade, 0.),
            None => (progress, slide_offset(progress)),
        };
        div()
            .id("launcher-island")
            // Its own presses mustn't close it first.
            .on_mouse_down(MouseButton::Left, |_, _, cx| cx.stop_propagation())
            .on_mouse_down(MouseButton::Right, |_, _, cx| cx.stop_propagation())
            .flex()
            .flex_col()
            .items_center()
            .overflow_hidden()
            .h(px(crate::bar_module::HEIGHT
                + body_height(rows) * island_motion(open)
                + COPIED_HEIGHT * island_motion(copied)))
            .opacity(opacity)
            .child(header)
            .when(open > 0., |island| {
                // Clipped to the animated width from the middle; the contents stay full width.
                island.child(
                    div()
                        .w(px(WIDTH * island_motion(open)))
                        .flex()
                        .justify_center()
                        .overflow_hidden()
                        .child(self.launcher_body(cx)),
                )
            })
            .when(copied > 0., |island| {
                island.child(
                    div()
                        .h(px(COPIED_HEIGHT * island_motion(copied)))
                        .flex_shrink_0()
                        .overflow_hidden()
                        .opacity(copied)
                        .child(
                            div()
                                .h(px(COPIED_HEIGHT))
                                .flex()
                                .items_center()
                                .text_size(px(12.))
                                .text_color(theme::CLOCK_ACCENT)
                                .child("Copied"),
                        ),
                )
            })
            // Offset visually only, like other peeked modules, and against the content row's.
            .relative()
            .top(px(offset - self.row_offset()))
            .map(|island| {
                if let Some((t, _)) = drip {
                    island.child(self.liquid_body(t, None, [false; 2], true))
                } else if shown {
                    island.child(self.liquid_anchor(progress, None, [false; 2]))
                } else {
                    island.invisible()
                }
            })
    }

    /// A mode in the selector, which switches to it (keeping what's typed).
    fn launcher_mode(&self, mode: Mode, selected: bool, cx: &mut Context<Self>) -> Stateful<Div> {
        let tooltip = match mode.prefix() {
            Some(prefix) => format!("{} ({prefix})", mode.name()),
            None => mode.name().to_owned(),
        };
        let color = if selected {
            theme::CLOCK_ACCENT
        } else {
            theme::MUTED
        };
        div()
            .id(("launcher-mode", mode as usize))
            .relative()
            .size(px(crate::bar_module::HEIGHT))
            .flex()
            .items_center()
            .justify_center()
            .rounded(px(4.))
            .cursor_pointer()
            .child(background("background").selected(selected))
            .child(tinted("icon", color, move |color| {
                static_icon(mode.icon(), color)
            }))
            .hoverable_tooltip(static_tooltip(tooltip.into(), theme::CLOCK_ACCENT))
            .on_click(cx.listener(move |this, _, _, cx| {
                // Not the header's, which closes the launcher.
                cx.stop_propagation();
                (this.sources.launcher).update(cx, |launcher, cx| launcher.set_mode(mode, cx))
            }))
    }

    fn launcher_body(&self, cx: &mut Context<Self>) -> Div {
        let launcher = self.sources.launcher.read(cx);
        let query = launcher.query.clone();
        let (mode, _) = launcher.mode();
        let selection = launcher.selection();
        let caret_first = launcher.cursor == selection.start;
        let caret = || {
            div()
                .w(px(1.5))
                .h(px(18.))
                .flex_shrink_0()
                .bg(theme::CLOCK_ACCENT)
        };
        let text = |range: std::ops::Range<usize>| {
            div()
                .flex_shrink_0()
                .text_color(theme::FOREGROUND)
                .child(query[range].to_owned())
        };
        let search = div()
            .h(px(SEARCH_HEIGHT))
            .flex_shrink_0()
            .px_3()
            .flex()
            .items_center()
            .gap_2()
            .rounded(px(8.))
            .bg(theme::CARD)
            .text_size(px(15.))
            .child(static_icon(Icon::Search, theme::MUTED))
            .child(
                div()
                    .min_w_0()
                    .flex()
                    .items_center()
                    .overflow_hidden()
                    .whitespace_nowrap()
                    .child(text(0..selection.start))
                    .when(caret_first, |field| field.child(caret()))
                    .when(!selection.is_empty(), |field| {
                        field.child(
                            text(selection.clone())
                                .rounded(px(2.))
                                .bg(theme::CLOCK_ACCENT.opacity(0.3)),
                        )
                    })
                    .when(!caret_first, |field| field.child(caret()))
                    .child(text(selection.end..query.len()))
                    .when(query.is_empty(), |field| {
                        field.child(div().text_color(theme::MUTED).child(mode.placeholder()))
                    }),
            );
        let results: Vec<(usize, Entry)> = (launcher.results().iter().enumerate())
            .skip(launcher.scroll)
            .take(VISIBLE)
            .map(|(index, entry)| (index, entry.clone()))
            .collect();
        let selected = launcher.selected;
        let empty = (results.is_empty()).then(|| {
            div()
                .h(px(RESULT_HEIGHT))
                .flex_shrink_0()
                .flex()
                .items_center()
                .justify_center()
                .text_size(px(14.))
                .text_color(theme::MUTED)
                .child(match mode {
                    Mode::Auto | Mode::Desktop if !launcher.scanned => "Loading…",
                    Mode::Files | Mode::Calculator if launcher.mode().1.is_empty() => "",
                    Mode::Menu => "No matches: Enter chooses what's typed",
                    _ => "No matches",
                })
        });
        div()
            .flex_shrink_0()
            .w(px(WIDTH))
            .flex()
            .flex_col()
            .px(px(LIST_PAD))
            .pt(px(LIST_PAD / 2.))
            .opacity(self.launcher_expand())
            .child(search)
            .child(div().h(px(LIST_PAD / 2.)).flex_shrink_0())
            .children(results.into_iter().map(|(index, entry)| {
                self.launcher_result(index, &entry, index == selected, mode == Mode::Auto, cx)
            }))
            .children(empty)
    }

    fn launcher_result(
        &self,
        index: usize,
        entry: &Entry,
        selected: bool,
        // In auto mode, each result shows which mode it's from.
        tagged: bool,
        cx: &mut Context<Self>,
    ) -> Stateful<Div> {
        let initial: String = (entry.name.chars().next())
            .map_or_else(String::new, |initial| initial.to_uppercase().collect());
        let letter = move || {
            div()
                .size(px(ICON_SIZE))
                .flex_shrink_0()
                .rounded_full()
                .flex()
                .items_center()
                .justify_center()
                .bg(theme::CLOCK_ACCENT.opacity(0.2))
                .text_size(px(14.))
                .text_color(theme::CLOCK_ACCENT)
                .child(initial.clone())
                .into_any_element()
        };
        let icon = match (&entry.icon, entry.mode) {
            (_, Mode::Emoji) => div()
                .size(px(ICON_SIZE))
                .flex_shrink_0()
                .flex()
                .items_center()
                .justify_center()
                .font_family("Noto Color Emoji")
                .text_size(px(22.))
                .child(entry.emoji().unwrap_or_default().to_owned())
                .into_any_element(),
            (Some(icon), _) => img(gpui::ImageSource::Render(icon.clone()))
                .size(px(ICON_SIZE))
                .flex_shrink_0()
                .object_fit(ObjectFit::Contain)
                .into_any_element(),
            (None, Mode::Desktop | Mode::Menu) => letter(),
            (None, mode) => div()
                .size(px(ICON_SIZE))
                .flex_shrink_0()
                .flex()
                .items_center()
                .justify_center()
                .child(static_icon(mode.icon(), theme::MUTED))
                .into_any_element(),
        };
        div()
            .id(("launcher-result", index))
            .h(px(RESULT_HEIGHT))
            .flex_shrink_0()
            .px_2()
            .flex()
            .items_center()
            .gap_2p5()
            .rounded(px(8.))
            .cursor_pointer()
            .relative()
            .child(background("background").selected(selected).radius(px(8.)))
            .child(icon)
            .child(
                div()
                    .flex_1()
                    .min_w_0()
                    .flex()
                    .flex_col()
                    .child(
                        div()
                            .truncate()
                            .text_size(px(15.))
                            .text_color(theme::FOREGROUND)
                            .child(entry.name.clone()),
                    )
                    .when(!entry.description.is_empty(), |text| {
                        text.child(
                            div()
                                .truncate()
                                .text_size(px(12.))
                                .text_color(theme::MUTED)
                                .child(entry.description.clone()),
                        )
                    }),
            )
            .when(tagged, |row| {
                row.child(
                    div()
                        .flex_shrink_0()
                        .text_size(px(12.))
                        .text_color(theme::MUTED)
                        .child(entry.mode.name()),
                )
            })
            .on_click(cx.listener(move |this, _, _, cx| this.launch(Some(index), false, cx)))
    }
}
