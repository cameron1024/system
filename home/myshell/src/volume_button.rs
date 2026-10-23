use gpui::AnyView;
use gpui::App;
use gpui::AppContext;
use gpui::Context;
use gpui::Entity;
use gpui::IntoElement;
use gpui::Render;
use gpui::Rgba;
use gpui::Window;
use gpui::div;
use gpui::prelude::*;

use crate::animated_icon::AnimatedIcon;
use crate::animated_icon::Icon;
use crate::data_source::Data;
use crate::data_source::volume::Volume;
use crate::data_source::volume::VolumeState;
use crate::theme;
use crate::tooltip::below_bar;
use crate::tooltip::tooltip;

fn icon(value: Option<&VolumeState>) -> Icon {
    match value {
        Some(value) if value.muted => Icon::Muted,
        Some(_) => Icon::Speaker,
        None => Icon::Unknown,
    }
}

fn color(value: Option<&VolumeState>) -> Rgba {
    if value.is_some_and(|value| value.muted) {
        theme::MUTED
    } else {
        theme::VOLUME_ACCENT
    }
}

pub struct VolumeButton {
    source: Entity<Data<Volume>>,
    icon: Entity<AnimatedIcon>,
}

impl VolumeButton {
    pub fn new(source: Entity<Data<Volume>>, cx: &mut Context<Self>) -> Self {
        let initial = icon(source.read(cx).state.target.as_ref());
        let tint = color(source.read(cx).state.target.as_ref());
        let animated = cx.new(|_| AnimatedIcon::new(initial, tint));
        cx.observe(&source, |this, source, cx| {
            let target = icon(source.read(cx).state.target.as_ref());
            let tint = color(source.read(cx).state.target.as_ref());
            this.icon.update(cx, |icon, cx| icon.set(target, tint, cx));
            cx.notify();
        })
        .detach();
        Self {
            source,
            icon: animated,
        }
    }

    pub fn tooltip(button: &Entity<Self>, window: &mut Window, cx: &mut App) -> AnyView {
        let source = button.read(cx).source.clone();
        let content = cx.new(|cx| {
            cx.observe(&source, |_, _, cx| cx.notify()).detach();
            VolumeTooltip { source }
        });
        below_bar(content, window, cx)
    }
}

impl Render for VolumeButton {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let value = self.source.read(cx).state.target.as_ref();
        let text = value.map_or_else(|| "--%".into(), |state| format!("{}%", state.percent));
        div()
            .text_color(color(value))
            .flex()
            .items_center()
            .gap_1()
            .child(self.icon.clone())
            .child(text)
    }
}

struct VolumeTooltip {
    source: Entity<Data<Volume>>,
}

impl Render for VolumeTooltip {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let source = self.source.read(cx);
        // Device identity is observed metadata, not an optimistic control value.
        let label = source
            .state
            .known
            .as_ref()
            .map_or("Output unavailable", |state| state.output.as_str());
        tooltip(label.to_owned(), theme::VOLUME_ACCENT)
    }
}
