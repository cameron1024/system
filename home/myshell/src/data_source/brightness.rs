//! The kernel doesn't announce backlight writes, so brightness is read at startup and after the
//! shell's own changes. External changes (e.g. `brightnessctl`) appear after the next one.

use std::io;

use futures::Stream;
use futures::StreamExt;
use futures::channel::mpsc;

use super::Data;
use super::DataSource;
use super::Result;

const BACKLIGHT: &str = "/sys/class/backlight";
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
    /// The panel the backlight belongs to, e.g. "BOE NE135A1M-NY1".
    pub display: String,
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

    const PERSISTENCE_KEY: Option<&str> = Some("brightness.available");

    async fn is_available() -> bool {
        std::fs::read_dir(BACKLIGHT).is_ok_and(|mut devices| devices.next().is_some())
    }

    fn stream(self) -> impl Stream<Item = Result<BrightnessState>> + Send + 'static {
        futures::stream::once(futures::future::ready(read())).chain(self.changed.map(|()| read()))
    }
}

fn read() -> Result<BrightnessState> {
    let device = std::fs::read_dir(BACKLIGHT)?
        .next()
        .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "no backlight device"))??;
    let path = device.path();
    let read = |name: &str| -> Result<u32> {
        Ok(std::fs::read_to_string(path.join(name))?.trim().parse()?)
    };
    let (raw, max) = (read("brightness")?, read("max_brightness")?);
    let display = display_name(&path).unwrap_or_else(|| "Display".into());
    if max == 0 {
        return Err(io::Error::other("backlight max_brightness is 0").into());
    }
    Ok(BrightnessState {
        percent: to_percent(raw, max),
        display,
        device: device.file_name().to_string_lossy().into_owned(),
        max,
    })
}

/// From the EDID of the connector the backlight belongs to (`device` links to it on DRM
/// drivers): the manufacturer's PNP ID and the monitor name descriptor, falling back to the
/// connector name (e.g. "eDP-1").
fn display_name(backlight: &std::path::Path) -> Option<String> {
    let connector = std::fs::canonicalize(backlight.join("device")).ok()?;
    let fallback = || {
        let name = connector.file_name()?.to_str()?;
        // e.g. "card1-eDP-1".
        Some(
            name.split_once('-')
                .map_or(name, |(_, rest)| rest)
                .to_owned(),
        )
    };
    let Ok(edid) = std::fs::read(connector.join("edid")) else {
        return fallback();
    };
    edid_name(&edid).or_else(fallback)
}

fn edid_name(edid: &[u8]) -> Option<String> {
    if edid.len() < 128 {
        return None;
    }
    let id = u16::from_be_bytes([edid[8], edid[9]]);
    let manufacturer: String = [10, 5, 0]
        .map(|shift| char::from(b'@' + ((id >> shift) & 0x1f) as u8))
        .into_iter()
        .collect();
    // Four 18-byte descriptors; tag 0xFC is the monitor name, newline-terminated.
    let name = (54..126).step_by(18).find_map(|start| {
        let descriptor = &edid[start..start + 18];
        (descriptor[..3] == [0, 0, 0] && descriptor[3] == 0xfc).then(|| {
            String::from_utf8_lossy(&descriptor[5..])
                .split('\n')
                .next()
                .unwrap_or_default()
                .trim()
                .to_owned()
        })
    })?;
    Some(format!("{manufacturer} {name}"))
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
