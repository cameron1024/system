//! The launcher, which the clock grows into like the notifications module into its dropdown: the
//! clock slides to the right of a widening header (controls on its left), and a search field and
//! results drop below. While it's open, the bar takes the keyboard.

use gpui::KeyDownEvent;
use gpui::layer_shell::KeyboardInteractivity;

use super::*;
use crate::desktop_entry::App as DesktopApp;
use crate::launcher::ICON_SIZE;
use crate::launcher::Launcher;
use crate::launcher::Motion;
use crate::launcher::VISIBLE;

const WIDTH: f32 = 560.;
const SEARCH_HEIGHT: f32 = 40.;
const RESULT_HEIGHT: f32 = 46.;

/// Below the clock, at rest: the search field, then `rows` results (or a message).
fn body_height(rows: f32) -> f32 {
    LIST_PAD / 2. + SEARCH_HEIGHT + LIST_PAD / 2. + rows.max(1.) * RESULT_HEIGHT + LIST_PAD_BOTTOM
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

        if open {
            self.launcher_slides = !self.bar.visible;
            self.close_tray_menu(cx);
            if self.pinned {
                let action = ModuleAction::Notifications(NotificationAction::CloseDropdown);
                let _ = self.actions.unbounded_send(action);
            }
            if self.hover_open {
                self.hover_open = false;
                (self.dropdown).set(self.pinned, cx.reduce_motion(), Instant::now());
            }
            (self.sources.launcher).update(cx, |launcher, cx| launcher.open(cx));
        }
        cx.notify();
    }

    /// While the launcher is open, the bar has the keyboard (focused on the launcher).
    pub(super) fn sync_launcher_window(&mut self, window: &mut Window, cx: &mut App) {
        use KeyboardInteractivity::*;
        let keyboard = if self.launcher.visible {
            Exclusive
        } else if self.launcher_keyboard != None && self.outside_click.is_some() {
            // Handing over to a group watching for outside clicks: niri ends a popup grab
            // (dismissing it, as if clicked outside) when its parent loses the keyboard, so keep
            // it until that group closes.
            OnDemand
        } else {
            None
        };
        if keyboard != self.launcher_keyboard {
            window.set_keyboard_interactivity(keyboard);
            if keyboard == Exclusive {
                self.launcher_focus.focus(window, cx);
            }
        }
        self.launcher_keyboard = keyboard;
    }

    fn launcher_key(&mut self, event: &KeyDownEvent, cx: &mut Context<Self>) {
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
            ("escape", _) => self.set_launcher(false, cx),
            ("enter", _) => self.launch(None, cx),
            ("up", _) | ("p", true) => with(cx, &|l, cx| l.select(-1, cx)),
            ("down", _) | ("n", true) => with(cx, &|l, cx| l.select(1, cx)),
            ("tab", _) => with(cx, &|l, cx| l.select(if shift { -1 } else { 1 }, cx)),
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
    fn launch(&mut self, index: Option<usize>, cx: &mut Context<Self>) {
        let launcher = self.sources.launcher.read(cx);
        let app = match index {
            Some(index) => launcher.results().nth(index),
            None => launcher.selected_app(),
        };
        if let Some(app) = app.cloned() {
            cx.background_executor()
                .spawn(async move {
                    if let Err(error) = app.launch() {
                        eprintln!("launching {}: {error}", app.id);
                    }
                })
                .detach();
        }
        self.set_launcher(false, cx);
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
        // Open, it stays in place while the bar shows or hides around it.
        let hold = self.launcher_progress;
        let progress = if self.bar.hidden() {
            peek.unwrap_or(0.).max(hold)
        } else {
            self.bar_progress.max(hold)
        };
        let shown = !self.bar.hidden() || peek.is_some() || !self.launcher.hidden();
        let scale = START_SCALE + (1. - START_SCALE) * progress;
        let clock = bar_module(
            Module::Clock.name(),
            scaled(scale, time),
            theme::CLOCK_ACCENT,
        )
        .flex_shrink_0()
        .when(self.launcher.visible, |clock| clock.bg(theme::SELECTED))
        .when(tooltips_enabled && !self.launcher.visible, |clock| {
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
        }));
        // The controls fill the space left of the clock, clipped to it as the header widens.
        // With no width of their own, they never affect the island's.
        let header = div()
            .flex()
            .min_w(px(WIDTH * open))
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
                                .child(self.launcher_control(
                                    "launcher-close",
                                    Icon::Close,
                                    cx.listener(|this, _, _, cx| this.set_launcher(false, cx)),
                                )),
                        )
                    }),
            )
            .child(clock);
        let rows = self.launcher_rows.value(now);
        div()
            .id("launcher-island")
            // Its own presses mustn't close it first.
            .on_mouse_down(MouseButton::Left, |_, _, cx| cx.stop_propagation())
            .on_mouse_down(MouseButton::Right, |_, _, cx| cx.stop_propagation())
            .track_focus(&self.launcher_focus)
            .on_key_down(cx.listener(|this, event, _, cx| this.launcher_key(event, cx)))
            .flex()
            .flex_col()
            .items_center()
            .overflow_hidden()
            .h(px(crate::bar_module::HEIGHT + body_height(rows) * open))
            .opacity(progress)
            .child(header)
            .when(open > 0., |island| {
                // Clipped to the animated width from the middle; the contents stay full width.
                island.child(
                    div()
                        .w(px(WIDTH * open))
                        .flex()
                        .justify_center()
                        .overflow_hidden()
                        .child(self.launcher_body(cx)),
                )
            })
            // Offset visually only, like other peeked modules, and against the content row's.
            .relative()
            .top(px(slide_offset(progress) - self.row_offset()))
            .map(|island| {
                if shown {
                    island.child(self.liquid_anchor(progress, None, [false; 2]))
                } else {
                    island.invisible()
                }
            })
    }

    fn launcher_control(
        &self,
        id: &'static str,
        icon: Icon,
        on_click: impl Fn(&gpui::ClickEvent, &mut Window, &mut App) + 'static,
    ) -> Stateful<Div> {
        div()
            .id(id)
            .size(px(crate::bar_module::HEIGHT))
            .flex()
            .items_center()
            .justify_center()
            .rounded(px(4.))
            .cursor_pointer()
            .hover(|button| button.bg(theme::MODULE_HOVER))
            .child(static_icon(icon, theme::FOREGROUND))
            .on_click(on_click)
    }

    fn launcher_body(&self, cx: &mut Context<Self>) -> Div {
        let launcher = self.sources.launcher.read(cx);
        let query = launcher.query.clone();
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
                        field.child(div().text_color(theme::MUTED).child("Search apps"))
                    }),
            );
        let results: Vec<(usize, DesktopApp)> = (launcher.results().enumerate())
            .skip(launcher.scroll)
            .take(VISIBLE)
            .map(|(index, app)| (index, app.clone()))
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
                .child(if !launcher.scanned {
                    "Loading apps…"
                } else if query.is_empty() {
                    "No apps"
                } else {
                    "No matches"
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
            .children(
                results
                    .into_iter()
                    .map(|(index, app)| self.launcher_result(index, &app, index == selected, cx)),
            )
            .children(empty)
    }

    fn launcher_result(
        &self,
        index: usize,
        app: &DesktopApp,
        selected: bool,
        cx: &mut Context<Self>,
    ) -> Stateful<Div> {
        let initial: String = (app.name.chars().next())
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
        let icon = match &app.icon {
            Some(icon) => img(gpui::ImageSource::Render(icon.clone()))
                .size(px(ICON_SIZE))
                .flex_shrink_0()
                .object_fit(ObjectFit::Contain)
                .into_any_element(),
            None => letter(),
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
            .when(selected, |row| row.bg(theme::SELECTED))
            .hover(|row| row.bg(theme::MODULE_HOVER))
            .child(icon)
            .child(
                div()
                    .min_w_0()
                    .flex()
                    .flex_col()
                    .child(
                        div()
                            .truncate()
                            .text_size(px(15.))
                            .text_color(theme::FOREGROUND)
                            .child(app.name.clone()),
                    )
                    .when(!app.description.is_empty(), |text| {
                        text.child(
                            div()
                                .truncate()
                                .text_size(px(12.))
                                .text_color(theme::MUTED)
                                .child(app.description.clone()),
                        )
                    }),
            )
            .on_click(cx.listener(move |this, _, _, cx| this.launch(Some(index), cx)))
    }
}
