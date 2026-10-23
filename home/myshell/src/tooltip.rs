use gpui::AnyElement;
use gpui::AnyView;
use gpui::App;
use gpui::AppContext;
use gpui::AvailableSpace;
use gpui::Bounds;
use gpui::Context;
use gpui::Div;
use gpui::Entity;
use gpui::IntoElement;
use gpui::Pixels;
use gpui::Render;
use gpui::Rgba;
use gpui::SharedString;
use gpui::Size;
use gpui::Window;
use gpui::WindowBackgroundAppearance;
use gpui::WindowBounds;
use gpui::WindowKind;
use gpui::WindowOptions;
use gpui::div;
use gpui::point;
use gpui::popup::PopupAnchor;
use gpui::popup::PopupConstraintAdjustment;
use gpui::popup::PopupGravity;
use gpui::popup::PopupOptions;
use gpui::prelude::*;
use gpui::px;
use gpui::size;

use crate::theme;

/// Retain GPUI's hover delay/lifetime, but render the content in a native, passive popup.
/// Dropping its in-window placeholder (including on a fast window leave) closes the popup.
pub fn below_bar<T: Render + 'static>(
    content: Entity<T>,
    window: &mut Window,
    cx: &mut App,
) -> AnyView {
    if !window.is_window_hovered() {
        return cx.new(|_| TooltipAnchor).into();
    }
    let mut element = content.clone().into_any_element();
    let dimensions = measure(&mut element, window, cx);
    let options = WindowOptions {
        titlebar: None,
        focus: false,
        window_background: WindowBackgroundAppearance::Transparent,
        window_bounds: Some(WindowBounds::Windowed(Bounds {
            origin: point(px(0.), px(0.)),
            size: dimensions,
        })),
        kind: WindowKind::AnchoredPopup(PopupOptions {
            parent: window.window_handle(),
            anchor_rect: Bounds {
                origin: point(window.mouse_position().x, px(0.)),
                size: size(px(1.), window.viewport_size().height),
            },
            anchor: PopupAnchor::BottomLeft,
            gravity: PopupGravity::BottomRight,
            // Horizontal adjustment is fine; never flip/slide vertically over the bar.
            constraint_adjustment: PopupConstraintAdjustment::SLIDE_X,
            offset: point(px(0.), px(4.)),
            grab: false,
        }),
        ..Default::default()
    };
    let popup = cx.open_window(options, |window, cx| {
        window.set_input_region(Some(&[]));
        cx.new(|cx| {
            cx.observe(&content, |_, _, cx| cx.notify()).detach();
            TooltipPopup { content }
        })
    });
    cx.new(|cx| {
        match popup {
            Ok(popup) => cx
                .on_release(move |_, cx| {
                    let _ = popup.update(cx, |_, window, _| window.remove_window());
                })
                .detach(),
            Err(error) => eprintln!("opening tooltip: {error}"),
        }
        TooltipAnchor
    })
    .into()
}

struct TooltipAnchor;

impl Render for TooltipAnchor {
    fn render(&mut self, _: &mut Window, _: &mut Context<Self>) -> impl IntoElement {
        // Nothing is painted inside the bar itself.
        div().size_0()
    }
}

struct TooltipPopup<T: Render> {
    content: Entity<T>,
}

impl<T: Render + 'static> Render for TooltipPopup<T> {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let mut element = self.content.clone().into_any_element();
        let dimensions = measure(&mut element, window, cx);
        if dimensions != window.viewport_size() {
            window.resize(dimensions);
        }
        // Measurement consumes the element's layout phase; GPUI needs a fresh element.
        self.content.clone()
    }
}

fn measure(element: &mut AnyElement, window: &mut Window, cx: &mut App) -> Size<Pixels> {
    let bounds = element.layout_as_root(
        size(AvailableSpace::MaxContent, AvailableSpace::MaxContent),
        window,
        cx,
    );
    size(
        px(f32::from(bounds.width).ceil().max(1.)),
        px(f32::from(bounds.height).ceil().max(1.)),
    )
}

pub fn tooltip(text: impl Into<SharedString>, accent: Rgba) -> Div {
    let text: SharedString = text.into();
    div()
        .h(px(24.))
        .px_2()
        .flex()
        .items_center()
        .rounded(px(4.))
        .border_1()
        .border_color(accent)
        .bg(theme::MODULE_HOVER)
        .text_color(theme::FOREGROUND)
        .font_family("Josefin Sans")
        .text_size(px(14.))
        .whitespace_nowrap()
        .child(text)
}
