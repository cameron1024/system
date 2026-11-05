//! Elements that appear and disappear: their width eases (so neighbours slide, rather than
//! jump) and they fade, both following a progress from 0 (gone) to 1 (shown).

use std::cell::Cell;
use std::rc::Rc;

use gpui::AnyElement;
use gpui::App;
use gpui::ElementId;
use gpui::IntoElement;
use gpui::Pixels;
use gpui::RenderOnce;
use gpui::Size;
use gpui::Window;
use gpui::canvas;
use gpui::div;
use gpui::prelude::*;

/// `id` must be unique among its siblings, and stable while it's shown.
pub fn collapse(id: impl Into<ElementId>, progress: f32, child: impl IntoElement) -> Collapse {
    Collapse {
        id: id.into(),
        progress,
        child: child.into_any_element(),
    }
}

#[derive(IntoElement)]
pub struct Collapse {
    id: ElementId,
    progress: f32,
    child: AnyElement,
}

impl RenderOnce for Collapse {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        // The child's natural size, measured whenever it's laid out (at rest, in place).
        let measured = window.with_element_namespace(self.id.clone(), |window| {
            let state =
                window.use_keyed_state("size", cx, |_, _| Rc::new(Cell::new(None::<Size<Pixels>>)));
            state.read(cx).clone()
        });
        let size = measured.get();
        let measure = canvas(
            move |bounds, _, _| measured.set(Some(bounds.size)),
            |_, _, _, _| {},
        )
        .absolute()
        .inset_0();
        let wrapper = div().id(self.id).relative().flex_shrink_0();
        // At rest, laid out exactly as if it weren't wrapped.
        if self.progress >= 1. {
            return wrapper.child(self.child).child(measure);
        }
        // Otherwise it keeps its natural size, clipped to a share of it. Before it's ever been
        // measured (appearing), it takes no space until the frame after.
        let size = size.unwrap_or_default();
        wrapper
            .w(size.width * crate::reveal::island_motion(self.progress))
            .h(size.height)
            .overflow_hidden()
            .opacity(self.progress)
            .child(
                div()
                    .absolute()
                    .top_0()
                    .left_0()
                    .flex()
                    .items_start()
                    .whitespace_nowrap()
                    .when(size.width > Pixels::ZERO, |inner| inner.w(size.width))
                    .child(self.child)
                    .child(measure),
            )
    }
}
