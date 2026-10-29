//! Scales rem-sized content (text and icons) by overriding the rem size for its subtree. GPUI has
//! no general transform, so this re-lays-out the content at the new size.

use gpui::AnyElement;
use gpui::App;
use gpui::Bounds;
use gpui::Element;
use gpui::ElementId;
use gpui::GlobalElementId;
use gpui::InspectorElementId;
use gpui::IntoElement;
use gpui::LayoutId;
use gpui::Pixels;
use gpui::Window;
use gpui::px;

/// The rem size at a scale of 1.
pub const REM: f32 = 16.;

pub fn scaled(scale: f32, child: impl IntoElement) -> Scaled {
    Scaled {
        rem: px(REM * scale),
        child: child.into_any_element(),
    }
}

pub struct Scaled {
    rem: Pixels,
    child: AnyElement,
}

impl IntoElement for Scaled {
    type Element = Self;

    fn into_element(self) -> Self {
        self
    }
}

impl Element for Scaled {
    type RequestLayoutState = ();
    type PrepaintState = ();

    fn id(&self) -> Option<ElementId> {
        None
    }

    fn source_location(&self) -> Option<&'static std::panic::Location<'static>> {
        None
    }

    fn request_layout(
        &mut self,
        _: Option<&GlobalElementId>,
        _: Option<&InspectorElementId>,
        window: &mut Window,
        cx: &mut App,
    ) -> (LayoutId, ()) {
        let child = &mut self.child;
        let layout =
            window.with_rem_size(Some(self.rem), |window| child.request_layout(window, cx));
        (layout, ())
    }

    fn prepaint(
        &mut self,
        _: Option<&GlobalElementId>,
        _: Option<&InspectorElementId>,
        _: Bounds<Pixels>,
        _: &mut (),
        window: &mut Window,
        cx: &mut App,
    ) {
        let child = &mut self.child;
        window.with_rem_size(Some(self.rem), |window| {
            child.prepaint(window, cx);
        });
    }

    fn paint(
        &mut self,
        _: Option<&GlobalElementId>,
        _: Option<&InspectorElementId>,
        _: Bounds<Pixels>,
        _: &mut (),
        _: &mut (),
        window: &mut Window,
        cx: &mut App,
    ) {
        let child = &mut self.child;
        window.with_rem_size(Some(self.rem), |window| child.paint(window, cx));
    }
}
