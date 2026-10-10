use gpui::{Context, Entity, IntoElement, Render, Window, div, prelude::*, px, rgb};

use crate::clock::Clock;

pub const HEIGHT: f32 = 32.;

pub struct Bar {
    clock: Entity<Clock>,
}

impl Bar {
    pub fn new(clock: Entity<Clock>, cx: &mut Context<Self>) -> Self {
        cx.observe(&clock, |_, _, cx| cx.notify()).detach();
        Self { clock }
    }
}

impl Render for Bar {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        // Equal-width flex-1 sides keep the center truly centered regardless of side content.
        div()
            .size_full()
            .flex()
            .items_center()
            .px_3()
            .bg(rgb(0x1e1e2e))
            .text_color(rgb(0xcdd6f4))
            .text_size(px(14.))
            .child(div().flex_1())
            .child(self.clock.read(cx).text())
            .child(div().flex_1())
    }
}
