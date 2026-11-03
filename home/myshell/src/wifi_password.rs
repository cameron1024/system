use std::ops::Range;

use gpui::App;
use gpui::Bounds;
use gpui::Context;
use gpui::ElementInputHandler;
use gpui::EntityInputHandler;
use gpui::EventEmitter;
use gpui::FocusHandle;
use gpui::KeyDownEvent;
use gpui::Pixels;
use gpui::Point;
use gpui::UTF16Selection;
use gpui::Window;
use gpui::canvas;
use gpui::div;
use gpui::prelude::*;

pub struct Submit;

pub struct WifiPassword {
    focus: FocusHandle,
    text: String,
    selection: Range<usize>,
    marked: Option<Range<usize>>,
    caret_visible: bool,
    blink_task: Option<gpui::Task<()>>,
    last_edit: std::time::Instant,
}

impl EventEmitter<Submit> for WifiPassword {}

// Internal ranges are UTF-8 byte offsets; platform input ranges are UTF-16.
fn byte_offset(text: &str, offset: usize) -> usize {
    let mut units = 0;
    for (index, ch) in text.char_indices() {
        if units + ch.len_utf16() > offset {
            return index;
        }
        units += ch.len_utf16();
    }
    text.len()
}

impl WifiPassword {
    pub fn new(cx: &mut Context<Self>) -> Self {
        Self {
            focus: cx.focus_handle(),
            text: String::new(),
            selection: 0..0,
            marked: None,
            caret_visible: true,
            blink_task: None,
            last_edit: std::time::Instant::now(),
        }
    }

    pub fn focus(&self, window: &mut Window, cx: &mut App) {
        window.focus(&self.focus, cx);
    }

    pub fn take(&mut self, cx: &mut Context<Self>) -> String {
        self.selection = 0..0;
        self.marked = None;
        cx.notify();
        std::mem::take(&mut self.text)
    }

    fn bytes(&self, range: Range<usize>) -> Range<usize> {
        byte_offset(&self.text, range.start)..byte_offset(&self.text, range.end)
    }

    fn utf16(&self, range: Range<usize>) -> Range<usize> {
        self.text[..range.start].encode_utf16().count()
            ..self.text[..range.end].encode_utf16().count()
    }

    fn replace(&mut self, range: Option<Range<usize>>, text: &str) -> usize {
        let range = range
            .map(|range| self.bytes(range))
            .or_else(|| self.marked.clone())
            .unwrap_or_else(|| self.selection.clone());
        self.caret_visible = true;
        self.last_edit = std::time::Instant::now();
        self.text.replace_range(range.clone(), text);
        self.selection = range.start + text.len()..range.start + text.len();
        self.marked = None;
        range.start
    }

    fn key(&mut self, event: &KeyDownEvent, window: &mut Window, cx: &mut Context<Self>) {
        let key = &event.keystroke;
        match key.key.as_str() {
            "enter" => cx.emit(Submit),
            "escape" => return,
            "a" if key.modifiers.control || key.modifiers.platform => {
                self.selection = 0..self.text.len();
            }
            "v" if key.modifiers.control || key.modifiers.platform => {
                if let Some(text) = cx.read_from_clipboard().and_then(|item| item.text()) {
                    self.replace_text_in_range(None, text.lines().next().unwrap_or(""), window, cx);
                }
            }
            "backspace" | "delete" => {
                if self.selection.is_empty() {
                    let cursor = self.selection.start;
                    if key.key == "backspace" {
                        self.selection.start = self.text[..cursor]
                            .char_indices()
                            .next_back()
                            .map_or(0, |(index, _)| index);
                    } else {
                        self.selection.end =
                            cursor + self.text[cursor..].chars().next().map_or(0, char::len_utf8);
                    }
                }
                self.replace(None, "");
            }
            "left" | "right" | "home" | "end" => {
                let cursor = self.selection.end;
                let target = match key.key.as_str() {
                    "home" => 0,
                    "end" => self.text.len(),
                    "left" => self.text[..cursor]
                        .char_indices()
                        .next_back()
                        .map_or(0, |(i, _)| i),
                    _ => cursor + self.text[cursor..].chars().next().map_or(0, char::len_utf8),
                };
                self.selection = target..target;
                self.marked = None;
            }
            _ => return,
        }
        self.caret_visible = true;
        self.last_edit = std::time::Instant::now();
        cx.stop_propagation();
        cx.notify();
    }
}

impl EntityInputHandler for WifiPassword {
    fn text_for_range(
        &mut self,
        range: Range<usize>,
        actual: &mut Option<Range<usize>>,
        _: &mut Window,
        _: &mut Context<Self>,
    ) -> Option<String> {
        let range = self.bytes(range);
        *actual = Some(self.utf16(range.clone()));
        Some(self.text[range].to_owned())
    }

    fn selected_text_range(
        &mut self,
        _: bool,
        _: &mut Window,
        _: &mut Context<Self>,
    ) -> Option<UTF16Selection> {
        Some(UTF16Selection {
            range: self.utf16(self.selection.clone()),
            reversed: false,
        })
    }

    fn marked_text_range(&self, _: &mut Window, _: &mut Context<Self>) -> Option<Range<usize>> {
        self.marked.clone().map(|range| self.utf16(range))
    }

    fn unmark_text(&mut self, _: &mut Window, cx: &mut Context<Self>) {
        self.marked = None;
        cx.notify();
    }

    fn replace_text_in_range(
        &mut self,
        range: Option<Range<usize>>,
        text: &str,
        _: &mut Window,
        cx: &mut Context<Self>,
    ) {
        self.replace(range, text);
        cx.notify();
    }

    fn replace_and_mark_text_in_range(
        &mut self,
        range: Option<Range<usize>>,
        text: &str,
        selected: Option<Range<usize>>,
        _: &mut Window,
        cx: &mut Context<Self>,
    ) {
        let start = self.replace(range, text);
        self.marked = (!text.is_empty()).then_some(start..start + text.len());
        if let Some(range) = selected {
            self.selection =
                start + byte_offset(text, range.start)..start + byte_offset(text, range.end);
        }
        cx.notify();
    }

    fn bounds_for_range(
        &mut self,
        _: Range<usize>,
        bounds: Bounds<Pixels>,
        _: &mut Window,
        _: &mut Context<Self>,
    ) -> Option<Bounds<Pixels>> {
        Some(bounds)
    }

    fn character_index_for_point(
        &mut self,
        _: Point<Pixels>,
        _: &mut Window,
        _: &mut Context<Self>,
    ) -> Option<usize> {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::byte_offset;

    #[test]
    fn utf16_offsets_clamp_to_utf8_boundaries() {
        let text = "aé😀界";
        // An offset inside a surrogate pair rounds down to the character's start.
        for (offset, expected) in [
            (0, 0),
            (1, 1),
            (2, 3),
            (3, 3),
            (4, 7),
            (5, 10),
            (6, 10),
            (usize::MAX, 10),
        ] {
            let actual = byte_offset(text, offset);
            assert_eq!(actual, expected, "UTF-16 offset {offset}");
            assert!(text.is_char_boundary(actual));
        }
        assert_eq!(byte_offset("", 0), 0);
        assert_eq!(byte_offset("", usize::MAX), 0);
    }

    #[test]
    fn unicode_selection_and_replacement_use_byte_boundaries() {
        let mut text = "aé😀界z".to_owned();
        let range = byte_offset(&text, 1)..byte_offset(&text, 4);
        assert_eq!(&text[range.clone()], "é😀");
        assert_eq!(text[..range.start].encode_utf16().count(), 1);
        assert_eq!(text[..range.end].encode_utf16().count(), 4);

        let replacement = "🔑é";
        let start = range.start;
        text.replace_range(range, replacement);
        assert_eq!(text, "a🔑é界z");
        let cursor = start + replacement.len();
        assert_eq!(&text[cursor..], "界z");

        // Composition selection offsets are relative to the inserted text.
        let selection = start + byte_offset(replacement, 2)..start + byte_offset(replacement, 3);
        assert_eq!(&text[selection.clone()], "é");
        text.replace_range(selection, "");
        assert_eq!(text, "a🔑界z");
    }
}

impl Render for WifiPassword {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let entity = cx.entity();
        let focus = self.focus.clone();
        let focused = self.focus.is_focused(window);
        if focused && self.blink_task.is_none() {
            self.caret_visible = true;
            self.blink_task = Some(cx.spawn(async move |this, cx| {
                loop {
                    async_io::Timer::after(std::time::Duration::from_millis(500)).await;
                    if this
                        .update(cx, |this, cx| {
                            if this.last_edit.elapsed() >= std::time::Duration::from_millis(500) {
                                this.caret_visible = !this.caret_visible;
                                cx.notify();
                            }
                        })
                        .is_err()
                    {
                        break;
                    }
                }
            }));
        } else if !focused {
            self.blink_task = None;
        }
        let show_caret = focused && self.caret_visible && self.selection.is_empty();
        let caret = self.text[..self.selection.end].chars().count();
        let selected = self.text[..self.selection.start].chars().count()..caret;
        let content = div()
            .flex()
            .items_center()
            .children(self.text.chars().enumerate().map(|(index, _)| {
                div()
                    .relative()
                    .flex_shrink_0()
                    .w(gpui::px(9.))
                    .when(focused && selected.contains(&index), |cell| {
                        cell.bg(crate::theme::SELECTED)
                    })
                    .when(show_caret && index == caret, |cell| {
                        cell.border_l_1().border_color(crate::theme::WIFI_ACCENT)
                    })
                    .child("•")
            }))
            .when(
                show_caret && caret == self.text.chars().count(),
                |content| {
                    content.child(
                        div()
                            .flex_shrink_0()
                            .w(gpui::px(1.))
                            .h(gpui::px(16.))
                            .bg(crate::theme::WIFI_ACCENT),
                    )
                },
            );
        div()
            .track_focus(&self.focus)
            .on_key_down(cx.listener(Self::key))
            .on_mouse_down(
                gpui::MouseButton::Left,
                cx.listener(|this, _, window, cx| this.focus(window, cx)),
            )
            .relative()
            .w_full()
            .min_w_0()
            .h(gpui::px(32.))
            .px_2()
            .flex()
            .items_center()
            .rounded(gpui::px(4.))
            .border_1()
            .border_color(if focused {
                crate::theme::WIFI_ACCENT
            } else {
                crate::theme::MUTED
            })
            .bg(crate::theme::CARD)
            .text_color(crate::theme::FOREGROUND)
            .text_size(gpui::px(14.))
            .cursor_text()
            .overflow_hidden()
            .child(
                div()
                    .relative()
                    .flex_1()
                    .min_w_0()
                    .h(gpui::px(20.))
                    .flex()
                    .items_center()
                    .overflow_hidden()
                    .when(self.text.is_empty(), |field| {
                        field.child(
                            div()
                                .absolute()
                                .left_0()
                                .text_color(crate::theme::MUTED)
                                .child("Password"),
                        )
                    })
                    .child(content),
            )
            .child(
                canvas(
                    move |bounds, _, _| bounds,
                    move |bounds, _, window, cx| {
                        window.handle_input(&focus, ElementInputHandler::new(bounds, entity), cx);
                    },
                )
                .absolute()
                .size_full(),
            )
    }
}
