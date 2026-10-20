use futures::StreamExt;
use futures::channel::mpsc;
use gpui::Context;
use gpui::Entity;
use gpui::IntoElement;
use gpui::Render;
use gpui::Task;
use gpui::Window;
use gpui::div;
use gpui::prelude::*;
use gpui::px;

use crate::bar_module::bar_module;
use crate::data_source::Data;
use crate::data_source::Result;
use crate::data_source::clock::Clock;
use crate::data_source::power_profile::PowerProfile;
use crate::data_source::power_profile::Profile;
use crate::data_source::volume::Volume;
use crate::theme;

pub const HEIGHT: f32 = 32.;

pub struct Bar {
    clock: Entity<Data<Clock>>,
    power_profile: Entity<Data<PowerProfile>>,
    volume: Entity<Data<Volume>>,
    actions: mpsc::UnboundedSender<ModuleAction>,
    scroll_remainder: f32,
    _actions_task: Task<()>,
}

enum ModuleAction {
    CycleProfile,
    ToggleMute,
    Volume(i32),
}

impl ModuleAction {
    async fn run(self) -> Result<()> {
        match self {
            Self::CycleProfile => {
                let current = command("powerprofilesctl", &["get"]).await?;
                let next = match current.trim() {
                    "power-saver" => "balanced",
                    "balanced" => "performance",
                    _ => "power-saver",
                };
                command("powerprofilesctl", &["set", next]).await?;
            }
            Self::ToggleMute => {
                command("pactl", &["set-sink-mute", "@DEFAULT_SINK@", "toggle"]).await?;
            }
            Self::Volume(steps) => {
                let change = format!("{:+}%", steps * 5);
                command("pactl", &["set-sink-volume", "@DEFAULT_SINK@", &change]).await?;
            }
        }
        Ok(())
    }
}

async fn command(program: &str, args: &[&str]) -> Result<String> {
    let output = async_process::Command::new(program)
        .args(args)
        .env("LC_ALL", "C")
        .kill_on_drop(true)
        .output()
        .await?;
    if !output.status.success() {
        return Err(std::io::Error::other(format!(
            "{program} {}: {}: {}",
            args.join(" "),
            output.status,
            String::from_utf8_lossy(&output.stderr).trim(),
        ))
        .into());
    }
    Ok(String::from_utf8(output.stdout)?)
}

impl Bar {
    pub fn new(
        clock: Entity<Data<Clock>>,
        power_profile: Entity<Data<PowerProfile>>,
        volume: Entity<Data<Volume>>,
        cx: &mut Context<Self>,
    ) -> Self {
        cx.observe(&clock, |_, _, cx| cx.notify()).detach();
        cx.observe(&power_profile, |_, _, cx| cx.notify()).detach();
        cx.observe(&volume, |_, _, cx| cx.notify()).detach();
        let (actions, mut receiver) = mpsc::unbounded::<ModuleAction>();
        // Serialize commands so rapid clicks/scrolls don't race or spawn concurrent processes.
        let actions_task = cx.spawn(async move |_, _| {
            while let Some(action) = receiver.next().await {
                if let Err(error) = action.run().await {
                    eprintln!("bar action: {error}");
                }
            }
        });
        Self {
            clock,
            power_profile,
            volume,
            actions,
            scroll_remainder: 0.,
            _actions_task: actions_task,
        }
    }
}

impl Render for Bar {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let power = self.power_profile.read(cx);
        let profile = match power.value.as_ref() {
            Some(Profile::PowerSaver) => "Power saver",
            Some(Profile::Balanced) => "Balanced",
            Some(Profile::Performance) => "Performance",
            Some(Profile::Unknown(name)) => name.as_str(),
            None if power.error.is_some() => "Power unavailable",
            None => "Power …",
        }
        .to_owned();
        let volume = self.volume.read(cx);
        let volume_text = match volume.value {
            Some(value) if value.muted => format!("Muted · {}%", value.percent),
            Some(value) => format!("Volume {}%", value.percent),
            None if volume.error.is_some() => "Volume unavailable".into(),
            None => "Volume …".into(),
        };
        let clock = self
            .clock
            .read(cx)
            .value
            .clone()
            .unwrap_or_else(|| "--:--".into());

        // Content-sized groups, with flexible spacers taking the remaining width.
        div()
            .size_full()
            .flex()
            .items_center()
            .px_3()
            .bg(theme::BACKGROUND)
            .text_color(theme::FOREGROUND)
            .font_family("Josefin Sans")
            .text_size(px(14.))
            .child(
                div().flex().flex_shrink_0().child(
                    bar_module("power-profile", profile, theme::POWER_ACCENT)
                        .cursor_pointer()
                        .on_click(cx.listener(|this, _, _, _| {
                            let _ = this.actions.unbounded_send(ModuleAction::CycleProfile);
                        })),
                ),
            )
            .child(div().flex_1())
            .child(bar_module("clock", clock, theme::CLOCK_ACCENT).flex_shrink_0())
            .child(div().flex_1())
            .child(
                div().flex().flex_shrink_0().justify_end().child(
                    bar_module("volume", volume_text, theme::VOLUME_ACCENT)
                        .cursor_pointer()
                        .on_click(cx.listener(|this, _, _, _| {
                            let _ = this.actions.unbounded_send(ModuleAction::ToggleMute);
                        }))
                        .on_scroll_wheel(cx.listener(
                            |this, event: &gpui::ScrollWheelEvent, _, cx| {
                                // Accumulate smooth touchpad deltas; one line/notch is a 5% step.
                                this.scroll_remainder +=
                                    f32::from(event.delta.pixel_delta(px(24.)).y) / 24.;
                                let steps = this.scroll_remainder.trunc() as i32;
                                this.scroll_remainder -= steps as f32;
                                if steps != 0 {
                                    let _ =
                                        this.actions.unbounded_send(ModuleAction::Volume(steps));
                                }
                                cx.stop_propagation();
                            },
                        )),
                ),
            )
    }
}
