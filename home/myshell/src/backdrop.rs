//! While the launcher is open, catches presses anywhere else on its display, which close it. It's
//! a surface of its own so the bar's can stay small: redrawing (and compositing) a display-sized
//! surface every animation frame is slow. This one is transparent, and only drawn when it opens.

use std::rc::Rc;

use gpui::App;
use gpui::Bounds;
use gpui::Context;
use gpui::Entity;
use gpui::IntoElement;
use gpui::Pixels;
use gpui::Render;
use gpui::Window;
use gpui::WindowBackgroundAppearance;
use gpui::WindowBounds;
use gpui::WindowHandle;
use gpui::WindowKind;
use gpui::WindowOptions;
use gpui::div;
use gpui::layer_shell::Anchor;
use gpui::layer_shell::KeyboardInteractivity;
use gpui::layer_shell::Layer;
use gpui::layer_shell::LayerShellOptions;
use gpui::point;
use gpui::prelude::*;
use gpui::px;

pub struct Backdrop {
    /// Presses above this reach the bar's surface, which is beneath this one.
    pub inset: Pixels,
    on_press: Rc<dyn Fn(&mut App)>,
}

impl Render for Backdrop {
    fn render(&mut self, window: &mut Window, _: &mut Context<Self>) -> impl IntoElement {
        let size = window.viewport_size();
        window.set_input_region(Some(&[Bounds::from_corners(
            point(px(0.), self.inset),
            point(size.width, size.height),
        )]));
        let on_press = self.on_press.clone();
        div()
            .size_full()
            .on_any_mouse_down(move |_, _, cx| on_press(cx))
    }
}

/// Over the bar's display. Overlay surfaces stack in the order they open, so it's above the bar.
pub fn open(
    window: &Window,
    inset: Pixels,
    on_press: impl Fn(&mut App) + 'static,
    cx: &mut App,
) -> Option<(WindowHandle<Backdrop>, Entity<Backdrop>)> {
    let display = window.display(cx)?;
    let options = WindowOptions {
        display_id: Some(display.id()),
        titlebar: None,
        focus: false,
        window_bounds: Some(WindowBounds::Windowed(Bounds::new(
            point(px(0.), px(0.)),
            display.bounds().size,
        ))),
        app_id: Some("myshell".into()),
        window_background: WindowBackgroundAppearance::Transparent,
        kind: WindowKind::LayerShell(LayerShellOptions {
            namespace: "myshell-backdrop".into(),
            layer: Layer::Overlay,
            anchor: Anchor::TOP | Anchor::BOTTOM | Anchor::LEFT | Anchor::RIGHT,
            // The whole display, including the bar's reserved space.
            exclusive_zone: Some(px(-1.)),
            keyboard_interactivity: KeyboardInteractivity::None,
            ..Default::default()
        }),
        ..Default::default()
    };
    let mut root = None;
    let handle = cx.open_window(options, |_, cx| {
        let entity = cx.new(|_| Backdrop {
            inset,
            on_press: Rc::new(on_press),
        });
        root = Some(entity.clone());
        entity
    });
    match handle {
        Ok(handle) => Some((handle, root?)),
        Err(error) => {
            eprintln!("opening backdrop: {error}");
            None
        }
    }
}
