use gpui::Div;
use gpui::ElementId;
use gpui::Rgba;

use gpui::Stateful;
use gpui::div;
use gpui::prelude::*;
use gpui::px;

use crate::fade::background;

pub const HEIGHT: f32 = 30.;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Module {
    Clock,
    PowerProfile,
    Cpu,
    Memory,
    Disk,
    Volume,
    Caffeine,
    Brightness,
    Battery,
    Notifications,
}

impl Module {
    pub const ALL: [Self; 10] = [
        Self::Notifications,
        Self::Caffeine,
        Self::Clock,
        Self::PowerProfile,
        Self::Cpu,
        Self::Memory,
        Self::Disk,
        Self::Volume,
        Self::Brightness,
        Self::Battery,
    ];

    /// Used for both element IDs and the D-Bus interface.
    pub fn name(self) -> &'static str {
        match self {
            Self::Clock => "clock",
            Self::PowerProfile => "power-profile",
            Self::Cpu => "cpu",
            Self::Memory => "memory",
            Self::Disk => "disk",
            Self::Volume => "volume",
            Self::Caffeine => "caffeine",
            Self::Notifications => "notifications",
            Self::Brightness => "brightness",
            Self::Battery => "battery",
        }
    }
}

/// A styled module that retains GPUI's standard click and scroll listener builders. Its
/// background fades in while hovered, and rests tinted while `selected` (e.g. open).
pub fn bar_module(
    id: impl Into<ElementId>,
    content: impl IntoElement,
    accent: Rgba,
    selected: bool,
) -> Stateful<Div> {
    let id = id.into();
    div()
        .id(id.clone())
        .relative()
        .px_1p5()
        .h(px(HEIGHT))
        .flex()
        .items_center()
        .rounded(px(4.))
        .text_color(accent)
        .child(background(id).selected(selected))
        .child(content)
}
