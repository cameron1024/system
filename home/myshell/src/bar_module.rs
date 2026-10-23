use gpui::Div;
use gpui::ElementId;
use gpui::Rgba;

use gpui::Stateful;
use gpui::div;
use gpui::prelude::*;
use gpui::px;

use crate::theme;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Module {
    Clock,
    PowerProfile,
    System,
    Volume,
    Brightness,
    Battery,
}

impl Module {
    pub const ALL: [Self; 6] = [
        Self::Clock,
        Self::PowerProfile,
        Self::System,
        Self::Volume,
        Self::Brightness,
        Self::Battery,
    ];

    /// Used for both element IDs and the D-Bus interface.
    pub fn name(self) -> &'static str {
        match self {
            Self::Clock => "clock",
            Self::PowerProfile => "power-profile",
            Self::System => "system",
            Self::Volume => "volume",
            Self::Brightness => "brightness",
            Self::Battery => "battery",
        }
    }
}

/// A styled module that retains GPUI's standard click and scroll listener builders.
pub fn bar_module(
    id: impl Into<ElementId>,
    content: impl IntoElement,
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
        .child(content)
}
