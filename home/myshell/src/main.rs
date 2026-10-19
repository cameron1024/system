mod bar;
mod clock;

use gpui::App;
use gpui::AppContext;
use gpui::Bounds;
use gpui::WindowBackgroundAppearance;
use gpui::WindowBounds;
use gpui::WindowKind;
use gpui::WindowOptions;
use gpui::layer_shell::Anchor;
use gpui::layer_shell::KeyboardInteractivity;
use gpui::layer_shell::Layer;
use gpui::layer_shell::LayerShellOptions;
use gpui::point;
use gpui::px;
use gpui::size;

use crate::bar::Bar;
use crate::clock::Clock;

fn main() {
    gpui_platform::application().run(|cx: &mut App| {
        let clock = cx.new(Clock::new);

        cx.open_window(
            WindowOptions {
                titlebar: None,
                focus: false,
                // Width 0 lets the compositor stretch the surface between the left/right anchors.
                window_bounds: Some(WindowBounds::Windowed(Bounds {
                    origin: point(px(0.), px(0.)),
                    size: size(px(0.), px(bar::HEIGHT)),
                })),
                app_id: Some("myshell".into()),
                window_background: WindowBackgroundAppearance::Opaque,
                kind: WindowKind::LayerShell(LayerShellOptions {
                    namespace: "myshell-bar".into(),
                    layer: Layer::Top,
                    anchor: Anchor::TOP | Anchor::LEFT | Anchor::RIGHT,
                    exclusive_zone: Some(px(bar::HEIGHT)),
                    keyboard_interactivity: KeyboardInteractivity::None,
                    ..Default::default()
                }),
                ..Default::default()
            },
            |_, cx| cx.new(|cx| Bar::new(clock, cx)),
        )
        .expect("failed to open bar (does the compositor support wlr-layer-shell?)");
    });
}
