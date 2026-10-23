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
use crate::data_source::battery::Battery;
use crate::data_source::battery::BatteryState;
use crate::theme;

fn icon(value: Option<&BatteryState>) -> Icon {
    match value {
        None => Icon::Unknown,
        Some(value) if value.charging => Icon::BatteryCharging,
        Some(value) => match value.percent {
            0..=10 => Icon::BatteryEmpty,
            11..=40 => Icon::BatteryLow,
            41..=80 => Icon::BatteryMedium,
            _ => Icon::BatteryFull,
        },
    }
}

fn color(value: Option<&BatteryState>) -> Rgba {
    match value.map(|value| value.percent) {
        Some(0..10) => theme::CRITICAL,
        Some(10..20) => theme::WARNING,
        _ => theme::BATTERY_ACCENT,
    }
}

pub struct BatteryIndicator {
    source: Entity<Data<Battery>>,
    icon: Entity<AnimatedIcon>,
}

impl BatteryIndicator {
    pub fn new(source: Entity<Data<Battery>>, cx: &mut Context<Self>) -> Self {
        let value = source.read(cx).state.target.as_ref();
        let (initial, tint) = (icon(value), color(value));
        let animated = cx.new(|_| AnimatedIcon::new(initial, tint));
        cx.observe(&source, |this, source, cx| {
            let value = source.read(cx).state.target.as_ref();
            let (target, tint) = (icon(value), color(value));
            this.icon.update(cx, |icon, cx| icon.set(target, tint, cx));
            cx.notify();
        })
        .detach();
        Self {
            source,
            icon: animated,
        }
    }
}

impl Render for BatteryIndicator {
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
