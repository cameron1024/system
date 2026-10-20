use futures::channel::mpsc;
use gpui::AppContext;
use gpui::Bounds;
use gpui::Context;
use gpui::Entity;
use gpui::FocusHandle;
use gpui::IntoElement;
use gpui::Render;
use gpui::SharedString;
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
use gpui::size;

use crate::bar::Bar;
use crate::bar::{self};
use crate::data_source::Data;
use crate::data_source::clock::Clock;
use crate::data_source::power_profile::PowerProfile;
use crate::data_source::volume::Volume;
use crate::shortcuts::Command;
use crate::theme;

pub struct Shell {
    clock: Entity<Data<Clock>>,
    power: Entity<Data<PowerProfile>>,
    volume: Entity<Data<Volume>>,
    bars: Vec<WindowHandle<Bar>>,
    overlays: Vec<WindowHandle<Overlay>>,
    commands: mpsc::UnboundedSender<Command>,
}

impl Shell {
    pub fn new(commands: mpsc::UnboundedSender<Command>, cx: &mut Context<Self>) -> Self {
        Self {
            clock: cx.new(|cx| Data::new(Clock, cx)),
            power: cx.new(|cx| Data::new(PowerProfile, cx)),
            volume: cx.new(|cx| Data::new(Volume, cx)),
            bars: Vec::new(),
            overlays: Vec::new(),
            commands,
        }
    }

    pub fn command(&mut self, command: Command, cx: &mut Context<Self>) {
        match command {
            Command::ToggleBar if self.bars.is_empty() => self.show_bars(cx),
            Command::ToggleBar => {
                for bar in self.bars.drain(..) {
                    let _ = bar.update(cx, |_, window, _| window.remove_window());
                }
            }
            Command::ToggleForeground if self.overlays.is_empty() => self.show_overlays(cx),
            Command::ToggleForeground => {
                for overlay in self.overlays.drain(..) {
                    let _ = overlay.update(cx, |_, window, _| window.remove_window());
                }
            }
        }
    }

    pub fn show_bars(&mut self, cx: &mut Context<Self>) {
        for display in cx.displays() {
            let clock = self.clock.clone();
            let power = self.power.clone();
            let volume = self.volume.clone();
            match cx.open_window(
                WindowOptions {
                    display_id: Some(display.id()),
                    titlebar: None,
                    focus: false,
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
                |_, cx| cx.new(|cx| Bar::new(clock, power, volume, cx)),
            ) {
                Ok(window) => self.bars.push(window),
                Err(error) => eprintln!("opening bar: {error}"),
            }
        }
    }

    fn show_overlays(&mut self, cx: &mut Context<Self>) {
        for display in cx.displays() {
            let commands = self.commands.clone();
            match cx.open_window(
                WindowOptions {
                    display_id: Some(display.id()),
                    titlebar: None,
                    focus: true,
                    window_bounds: Some(WindowBounds::Windowed(Bounds {
                        origin: point(px(0.), px(0.)),
                        size: size(px(0.), px(0.)),
                    })),
                    app_id: Some("myshell".into()),
                    window_background: WindowBackgroundAppearance::Transparent,
                    kind: WindowKind::LayerShell(LayerShellOptions {
                        namespace: "myshell-foreground".into(),
                        layer: Layer::Overlay,
                        anchor: Anchor::all(),
                        // Cover the bar's reserved area too, without reserving any space ourselves.
                        exclusive_zone: Some(px(-1.)),
                        keyboard_interactivity: KeyboardInteractivity::Exclusive,
                        ..Default::default()
                    }),
                    ..Default::default()
                },
                |window, cx| {
                    cx.new(|cx| {
                        let focus = cx.focus_handle();
                        window.focus(&focus, cx);
                        Overlay { focus, commands }
                    })
                },
            ) {
                Ok(window) => self.overlays.push(window),
                Err(error) => eprintln!("opening foreground overlay: {error}"),
            }
        }
    }
}

struct Overlay {
    focus: FocusHandle,
    commands: mpsc::UnboundedSender<Command>,
}

impl Render for Overlay {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .size_full()
            .bg(theme::FOREGROUND_OVERLAY)
            .font_family(SharedString::from("Josefin Sans"))
            .track_focus(&self.focus)
            .on_key_down(cx.listener(|this, event: &gpui::KeyDownEvent, _, cx| {
                // Global Super shortcuts are dispatched by niri, not duplicated here.
                // Escape provides a local escape hatch even without the compositor binding.
                if event.keystroke.key == "escape" && !event.is_held {
                    let _ = this.commands.unbounded_send(Command::ToggleForeground);
                }
                cx.stop_propagation();
            }))
            .on_key_up(|_, _, cx| cx.stop_propagation())
    }
}
