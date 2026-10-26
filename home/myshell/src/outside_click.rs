//! Learns of clicks outside the shell while one of its groups is open. Wayland only tells a
//! client about those through a grabbing popup, which the compositor dismisses on them, so this
//! is an invisible one. Clicks on the shell's own surfaces still reach it as usual.

use gpui::App;
use gpui::AppContext;
use gpui::Bounds;
use gpui::Context;
use gpui::Entity;
use gpui::IntoElement;
use gpui::Render;
use gpui::Window;
use gpui::WindowBackgroundAppearance;
use gpui::WindowBounds;
use gpui::WindowHandle;
use gpui::WindowKind;
use gpui::WindowOptions;
use gpui::div;
use gpui::point;
use gpui::popup::PopupAnchor;
use gpui::popup::PopupConstraintAdjustment;
use gpui::popup::PopupGravity;
use gpui::popup::PopupOptions;

use gpui::px;
use gpui::size;

pub struct OutsideClick;

impl Render for OutsideClick {
    fn render(&mut self, _: &mut Window, _: &mut Context<Self>) -> impl IntoElement {
        div()
    }
}

/// Must be called while handling a mouse press, or the compositor refuses the grab. Its root
/// is released when the compositor dismisses it.
pub fn open(
    window: &mut Window,
    cx: &mut App,
) -> Option<(WindowHandle<OutsideClick>, Entity<OutsideClick>)> {
    let one = size(px(1.), px(1.));
    let options = WindowOptions {
        titlebar: None,
        focus: false,
        window_background: WindowBackgroundAppearance::Transparent,
        window_bounds: Some(WindowBounds::Windowed(Bounds::new(
            point(px(0.), px(0.)),
            one,
        ))),
        kind: WindowKind::AnchoredPopup(PopupOptions {
            parent: window.window_handle(),
            anchor_rect: Bounds::new(point(px(0.), px(0.)), one),
            anchor: PopupAnchor::TopLeft,
            gravity: PopupGravity::BottomRight,
            constraint_adjustment: PopupConstraintAdjustment::empty(),
            offset: point(px(0.), px(0.)),
            grab: true,
        }),
        ..Default::default()
    };
    let mut root = None;
    let handle = cx.open_window(options, |window, cx| {
        window.set_input_region(Some(&[]));
        let entity = cx.new(|_| OutsideClick);
        root = Some(entity.clone());
        entity
    });
    match handle {
        Ok(handle) => Some((handle, root?)),
        Err(error) => {
            eprintln!("watching for outside clicks: {error}");
            None
        }
    }
}
