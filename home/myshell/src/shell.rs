use futures::StreamExt;
use futures::channel::mpsc;
use gpui::AppContext;
use gpui::Bounds;
use gpui::Context;
use gpui::Entity;
use gpui::Task;
use gpui::WindowBackgroundAppearance;
use gpui::WindowBounds;
use gpui::WindowHandle;
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
use crate::bar::ModuleAction;
use crate::bar::{self};
use crate::bar_module::Module;
use crate::data_source::Data;
use crate::data_source::clock::Clock;
use crate::data_source::power_profile::PowerProfile;
use crate::data_source::volume::Volume;
use crate::shortcuts::Command;

pub struct Shell {
    clock: Entity<Data<Clock>>,
    power: Entity<Data<PowerProfile>>,
    volume: Entity<Data<Volume>>,
    bars: Vec<WindowHandle<Bar>>,
    visible: bool,
    peek_timer: Option<Task<()>>,
    actions: mpsc::UnboundedSender<ModuleAction>,
    _actions_task: Task<()>,
}

impl Shell {
    pub fn new(cx: &mut Context<Self>) -> Self {
        let clock = cx.new(|cx| Data::new(Clock, cx));
        let power = cx.new(|cx| Data::new(PowerProfile, cx));
        let volume = cx.new(|cx| Data::new(Volume, cx));
        let (actions, mut receiver) = mpsc::unbounded::<ModuleAction>();
        let action_power = power.clone();
        let action_volume = volume.clone();
        // Apply targets immediately on the UI; Data queues the actual writes in the background.
        let actions_task = cx.spawn(async move |_, cx| {
            while let Some(action) = receiver.next().await {
                match action {
                    ModuleAction::Click(Module::Clock) => {}
                    ModuleAction::Click(Module::PowerProfile) => {
                        action_power.update(cx, |data, cx| data.cycle(cx));
                    }
                    ModuleAction::Click(Module::Volume) => {
                        action_volume.update(cx, |data, cx| data.toggle_mute(cx));
                    }
                    ModuleAction::Volume(steps) => {
                        action_volume.update(cx, |data, cx| data.change_volume(steps, cx));
                    }
                }
            }
        });
        Self {
            clock,
            power,
            volume,
            bars: Vec::new(),
            visible: true,
            peek_timer: None,
            actions,
            _actions_task: actions_task,
        }
    }

    pub fn command(&mut self, command: Command, cx: &mut Context<Self>) {
        match command {
            Command::ToggleBar => {
                self.peek_timer = None;
                self.visible = !self.visible;
                for bar in &self.bars {
                    let _ = bar.update(cx, |bar, window, cx| {
                        bar.set_visible(self.visible, window, cx);
                    });
                }
            }
            Command::Activate(module) => {
                let _ = self.actions.unbounded_send(ModuleAction::Click(module));
                if self.visible {
                    return;
                }
                for bar in &self.bars {
                    let _ = bar.update(cx, |bar, window, cx| bar.peek(module, window, cx));
                }
                // Replacing the task cancels the old deadline; only one timer remains active.
                self.peek_timer = Some(cx.spawn(async move |this, cx| {
                    async_io::Timer::after(std::time::Duration::from_secs(3)).await;
                    let _ = this.update(cx, |shell, cx| {
                        if !shell.visible {
                            for bar in &shell.bars {
                                let _ = bar.update(cx, |bar, window, cx| bar.hide_peek(window, cx));
                            }
                        }
                    });
                }));
            }
        }
    }

    pub fn show_bars(&mut self, cx: &mut Context<Self>) {
        for display in cx.displays() {
            let clock = self.clock.clone();
            let power = self.power.clone();
            let volume = self.volume.clone();
            let actions = self.actions.clone();
            match cx.open_window(
                WindowOptions {
                    display_id: Some(display.id()),
                    titlebar: None,
                    focus: false,
                    // Bars never take focus; don't apply GPUI's default 30fps inactive cap.
                    inactive_frame_interval: None,
                    window_bounds: Some(WindowBounds::Windowed(Bounds {
                        origin: point(px(0.), px(0.)),
                        size: size(px(0.), px(bar::HEIGHT)),
                    })),
                    app_id: Some("myshell".into()),
                    window_background: WindowBackgroundAppearance::Transparent,
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
                |_, cx| cx.new(|cx| Bar::new(clock, power, volume, actions, cx)),
            ) {
                Ok(window) => self.bars.push(window),
                Err(error) => eprintln!("opening bar: {error}"),
            }
        }
    }
}
