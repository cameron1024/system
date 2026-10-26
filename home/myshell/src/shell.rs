use std::sync::Arc;

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
use crate::bar::NotificationAction;
use crate::bar::{self};
use crate::bar_module::Module;
use crate::caffeine::Caffeine;
use crate::data_source::Data;
use crate::data_source::battery::Battery;
use crate::data_source::brightness::Brightness;
use crate::data_source::clock::Clock;
use crate::data_source::power_profile::PowerProfile;
use crate::data_source::system::System;
use crate::data_source::volume::Volume;
use crate::notifications::Arrived;
use crate::notifications::Notifications;
use crate::shortcuts::Command;
use crate::store::Store;

/// Shared by every bar, so each source runs once regardless of the number of displays.
#[derive(Clone)]
pub struct Sources {
    pub clock: Entity<Data<Clock>>,
    pub power: Entity<Data<PowerProfile>>,
    pub system: Entity<Data<System>>,
    pub volume: Entity<Data<Volume>>,
    pub brightness: Entity<Data<Brightness>>,
    pub battery: Entity<Data<Battery>>,
    pub caffeine: Entity<Caffeine>,
    pub notifications: Entity<Notifications>,
}

pub struct Shell {
    sources: Sources,
    bars: Vec<WindowHandle<Bar>>,
    visible: bool,
    dropdown: bool,
    /// One hide deadline per peeked module. Finished timers linger until replaced or cleared,
    /// which bounds this by the number of modules.
    peek_timers: Vec<(Module, Task<()>)>,
    actions: mpsc::UnboundedSender<ModuleAction>,
    _actions_task: Task<()>,
}

impl Shell {
    pub fn new(cx: &mut Context<Self>) -> Self {
        let store = Store::open()
            .inspect_err(|error| eprintln!("database unavailable: {error}"))
            .ok()
            .map(Arc::new);
        let (brightness, brightness_changed) = Brightness::new();
        let sources = Sources {
            clock: cx.new(|cx| Data::new(Clock, store.clone(), cx)),
            power: cx.new(|cx| Data::new(PowerProfile, store.clone(), cx)),
            system: cx.new(|cx| Data::new(System, store.clone(), cx)),
            volume: cx.new(|cx| Data::new(Volume, store.clone(), cx)),
            brightness: cx.new(|cx| Data::new(brightness, store.clone(), cx)),
            battery: cx.new(|cx| Data::new(Battery, store.clone(), cx)),
            caffeine: cx.new(|_| Caffeine::default()),
            notifications: cx.new(|cx| Notifications::new(store, cx)),
        };
        cx.subscribe(&sources.notifications, |shell, _, _: &Arrived, cx| {
            // The toasts also show the bell while the bar is hidden, for exactly as long.
            if !shell.dropdown {
                for bar in &shell.bars {
                    let _ = bar.update(cx, |bar, _, cx| bar.show_toast(cx));
                }
            }
        })
        .detach();
        let (actions, mut receiver) = mpsc::unbounded::<ModuleAction>();
        let targets = sources.clone();
        // Apply targets immediately on the UI; Data queues the actual writes in the background.
        let actions_task = cx.spawn(async move |this, cx| {
            while let Some(action) = receiver.next().await {
                match action {
                    ModuleAction::Click(Module::Notifications) => {
                        let _ =
                            this.update(cx, |shell, cx| shell.set_dropdown(!shell.dropdown, cx));
                    }
                    ModuleAction::Notifications(action) => {
                        targets
                            .notifications
                            .update(cx, |notifications, cx| match action {
                                NotificationAction::ToggleShowRead => {
                                    notifications.toggle_show_read(cx)
                                }
                                NotificationAction::LoadMore => notifications.load_more(),
                                // Mark-all-read animates, so the bar applies it directly.
                                NotificationAction::MarkAllRead
                                | NotificationAction::CloseDropdown => {}
                            });
                        if matches!(action, NotificationAction::CloseDropdown) {
                            let _ = this.update(cx, |shell, cx| shell.set_dropdown(false, cx));
                        }
                    }
                    ModuleAction::Click(Module::PowerProfile) => {
                        targets.power.update(cx, |data, cx| data.cycle(cx));
                    }
                    ModuleAction::Click(Module::Volume) => {
                        targets.volume.update(cx, |data, cx| data.toggle_mute(cx));
                    }
                    ModuleAction::Adjust(Module::Volume, steps) => {
                        targets
                            .volume
                            .update(cx, |data, cx| data.change_volume(steps, cx));
                    }
                    ModuleAction::Click(Module::Caffeine) => {
                        targets
                            .caffeine
                            .update(cx, |caffeine, cx| caffeine.toggle(cx));
                    }
                    ModuleAction::Click(Module::Brightness) => {
                        let changed = brightness_changed.clone();
                        targets
                            .brightness
                            .update(cx, |data, cx| data.cycle_brightness(changed, cx));
                    }
                    ModuleAction::Adjust(Module::Brightness, steps) => {
                        let changed = brightness_changed.clone();
                        targets
                            .brightness
                            .update(cx, |data, cx| data.change_brightness(steps, changed, cx));
                    }
                    ModuleAction::Click(_) | ModuleAction::Adjust(..) => {}
                }
            }
        });
        Self {
            sources,
            bars: Vec::new(),
            visible: true,
            dropdown: false,
            peek_timers: Vec::new(),
            actions,
            _actions_task: actions_task,
        }
    }

    pub fn command(&mut self, command: Command, cx: &mut Context<Self>) {
        match command {
            Command::ToggleBar => {
                self.peek_timers.clear();
                self.visible = !self.visible;
                for bar in &self.bars {
                    let _ = bar.update(cx, |bar, window, cx| {
                        bar.set_visible(self.visible, window, cx);
                    });
                }
            }
            Command::Activate(module) => self.act(ModuleAction::Click(module), module, cx),
            Command::Adjust(module, steps) => {
                self.act(ModuleAction::Adjust(module, steps), module, cx)
            }
        }
    }

    /// Performs the action, briefly showing its module if the bar is hidden. The notifications
    /// module shows itself, with its dropdown.
    fn act(&mut self, action: ModuleAction, module: Module, cx: &mut Context<Self>) {
        let _ = self.actions.unbounded_send(action);
        if module != Module::Notifications {
            self.peek(module, cx);
        }
    }

    fn set_dropdown(&mut self, open: bool, cx: &mut Context<Self>) {
        self.dropdown = open;
        for bar in &self.bars {
            let _ = bar.update(cx, |bar, _, cx| bar.set_dropdown(open, cx));
        }
    }

    /// Briefly shows a module if the bar is hidden.
    fn peek(&mut self, module: Module, cx: &mut Context<Self>) {
        if self.visible {
            return;
        }
        for bar in &self.bars {
            let _ = bar.update(cx, |bar, _, cx| bar.peek(module, cx));
        }
        // Replacing a module's task cancels its old deadline; other peeks keep theirs.
        self.peek_timers.retain(|(peeked, _)| *peeked != module);
        let timer = cx.spawn(async move |this, cx| {
            async_io::Timer::after(std::time::Duration::from_secs(3)).await;
            let _ = this.update(cx, |shell, cx| {
                if !shell.visible {
                    for bar in &shell.bars {
                        let _ = bar.update(cx, |bar, _, cx| bar.hide_peek(module, cx));
                    }
                }
            });
        });
        self.peek_timers.push((module, timer));
    }

    pub fn show_bars(&mut self, cx: &mut Context<Self>) {
        for display in cx.displays() {
            let sources = self.sources.clone();
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
                        // Non-zero width: GPUI sizes the viewport from these bounds if a
                        // fractional scale arrives before the first configure, and a zero
                        // width there is a fatal Wayland protocol error.
                        size: size(display.bounds().size.width, px(bar::HEIGHT)),
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
                |_, cx| cx.new(|cx| Bar::new(sources, actions, cx)),
            ) {
                Ok(window) => self.bars.push(window),
                Err(error) => eprintln!("opening bar: {error}"),
            }
        }
    }
}
