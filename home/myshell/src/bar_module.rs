use gpui::Div;
use gpui::ElementId;
use gpui::Rgba;
use gpui::SharedString;
use gpui::Stateful;
use gpui::div;
use gpui::prelude::*;
use gpui::px;

use crate::theme;

/// A styled module that retains GPUI's standard click and scroll listener builders.
pub fn bar_module(
    id: impl Into<ElementId>,
    text: impl Into<SharedString>,
    accent: Rgba,
) -> Stateful<Div> {
    div()
        .id(id)
        .px_2()
        .h(px(26.))
        .flex()
        .items_center()
        .rounded(px(4.))
        .border_1()
        .border_color(accent)
        .text_color(accent)
        .bg(theme::BACKGROUND)
        .hover(|style| style.bg(theme::MODULE_HOVER))
        .child(text.into())
}
