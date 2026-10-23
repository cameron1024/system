//! The kernel doesn't announce backlight writes, so brightness is read at startup and after the
//! shell's own changes. External changes (e.g. `brightnessctl`) appear after the next one.

use std::io;

use futures::Stream;
use futures::StreamExt;
use futures::channel::mpsc;

use super::Data;
use super::DataSource;
use super::Result;

const STEP: i32 = 10;
const PRESETS: [u32; 4] = [10, 30, 70, 100];

pub struct Brightness {
    changed: mpsc::UnboundedReceiver<()>,
}

impl Brightness {
    /// Pass the sender to `change_brightness` so successful writes are read back.
    pub fn new() -> (Self, mpsc::UnboundedSender<()>) {
        let (sender, changed) = mpsc::unbounded();
        (Self { changed }, sender)
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct BrightnessState {
    pub percent: u32,
    device: String,
    max: u32,
}

impl Data<Brightness> {
    pub fn change_brightness(
        &mut self,
        steps: i32,
        changed: mpsc::UnboundedSender<()>,
        cx: &mut gpui::Context<Self>,
    ) {
        self.set_brightness(
            |percent| {
                percent
                    .saturating_add_signed(steps.saturating_mul(STEP))
                    .min(100)
            },
            changed,
            cx,
        );
    }

    /// Moves to the next preset above the current value, wrapping to the lowest.
    pub fn cycle_brightness(
        &mut self,
        changed: mpsc::UnboundedSender<()>,
        cx: &mut gpui::Context<Self>,
    ) {
        self.set_brightness(next_preset, changed, cx);
    }

    fn set_brightness(
        &mut self,
        percent: impl FnOnce(u32) -> u32,
        changed: mpsc::UnboundedSender<()>,
        cx: &mut gpui::Context<Self>,
    ) {
        let Some(mut target) = self.state.target.clone() else {
            return;
        };
        target.percent = percent(target.percent);
        let value = to_raw(target.percent, target.max);
        let device = target.device.clone();
        self.request(
            target,
            async move {
                // logind lets the active session write without udev rules or setuid helpers.
                zbus::Connection::system()
                    .await?
                    .call_method(
                        Some("org.freedesktop.login1"),
                        "/org/freedesktop/login1/session/auto",
                        Some("org.freedesktop.login1.Session"),
                        "SetBrightness",
                        &("backlight", device.as_str(), value),
                    )
                    .await?;
                let _ = changed.unbounded_send(());
                Ok(())
            },
            cx,
        );
    }
}

impl DataSource for Brightness {
    type Value = BrightnessState;

    fn stream(self) -> impl Stream<Item = Result<BrightnessState>> + Send + 'static {
        futures::stream::once(futures::future::ready(read())).chain(self.changed.map(|()| read()))
    }
}

fn read() -> Result<BrightnessState> {
    let device = std::fs::read_dir("/sys/class/backlight")?
        .next()
        .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "no backlight device"))??;
    let path = device.path();
    let read = |name: &str| -> Result<u32> {
        Ok(std::fs::read_to_string(path.join(name))?.trim().parse()?)
    };
    let (raw, max) = (read("brightness")?, read("max_brightness")?);
    if max == 0 {
        return Err(io::Error::other("backlight max_brightness is 0").into());
    }
    Ok(BrightnessState {
        percent: to_percent(raw, max),
        device: device.file_name().to_string_lossy().into_owned(),
        max,
    })
}

fn next_preset(percent: u32) -> u32 {
    PRESETS
        .into_iter()
        .find(|&preset| preset > percent)
        .unwrap_or(PRESETS[0])
}

fn to_percent(raw: u32, max: u32) -> u32 {
    ((u64::from(raw) * 100 + u64::from(max) / 2) / u64::from(max)) as u32
}

fn to_raw(percent: u32, max: u32) -> u32 {
    ((u64::from(percent) * u64::from(max) + 50) / 100) as u32
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn presets_snap_upwards_and_wrap() {
        let cycle = [0, 10, 25, 30, 50, 70, 99, 100].map(next_preset);
        assert_eq!(cycle, [10, 30, 30, 70, 70, 100, 100, 10]);
    }

    #[test]
    fn written_percentages_read_back_unchanged() {
        // Otherwise a write is never confirmed by its read-back.
        for max in [100, 255, 937, 65535] {
            for percent in 0..=100 {
                assert_eq!(to_percent(to_raw(percent, max), max), percent, "{max}");
            }
        }
    }
}
