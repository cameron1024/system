use std::io;

use futures::Stream;
use futures::StreamExt;
use futures::TryStreamExt;
use zbus::fdo::PropertiesProxy;

use super::DataSource;
use super::Result;
use super::watch_properties;

const INTERFACE: &str = "org.freedesktop.UPower.Device";

pub struct Battery;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct BatteryState {
    pub percent: u32,
    pub charging: bool,
    full: bool,
    /// Seconds until empty (discharging) or full (charging); 0 while UPower is estimating.
    remaining: i64,
}

impl BatteryState {
    pub fn time_label(&self) -> String {
        if self.full {
            return "Fully charged".into();
        }
        if self.remaining <= 0 {
            return "Estimating time remaining…".into();
        }
        let minutes = self.remaining / 60;
        let time = match (minutes / 60, minutes % 60) {
            (0, m) => format!("{m}m"),
            (h, m) => format!("{h}h {m}m"),
        };
        if self.charging {
            format!("{time} until full")
        } else {
            format!("{time} remaining")
        }
    }
}

impl DataSource for Battery {
    type Value = BatteryState;

    fn stream(self) -> impl Stream<Item = Result<BatteryState>> + Send + 'static {
        futures::stream::once(async {
            // UPower's aggregate of all batteries, so there's no device discovery.
            let (properties, updates) = watch_properties(
                "org.freedesktop.UPower",
                "/org/freedesktop/UPower/devices/DisplayDevice",
                INTERFACE,
                &["Percentage", "State", "TimeToEmpty", "TimeToFull"],
            )
            .await?;
            Ok::<_, super::Error>(async_stream::stream! {
                futures::pin_mut!(updates);
                while let Some(update) = updates.next().await {
                    yield match update {
                        Ok(()) => read(&properties).await,
                        Err(error) => Err(error),
                    };
                }
                yield Err(io::Error::new(
                    io::ErrorKind::BrokenPipe,
                    "battery signal stream closed",
                ).into());
            })
        })
        .try_flatten()
    }
}

async fn read(properties: &PropertiesProxy<'_>) -> Result<BatteryState> {
    let mut all = properties.get_all(INTERFACE.try_into()?).await?;
    let mut take = |name| {
        all.remove(name)
            .ok_or_else(|| io::Error::other(format!("UPower is missing {name}")))
    };
    let percent = f64::try_from(take("Percentage")?)?;
    let state = u32::try_from(take("State")?)?;
    let to_empty = i64::try_from(take("TimeToEmpty")?)?;
    let to_full = i64::try_from(take("TimeToFull")?)?;
    // UPower: 1 = charging, 2 = discharging, 4 = fully charged, 5 = pending charge, ...
    let charging = state == 1;
    Ok(BatteryState {
        percent: percent.round().clamp(0., 100.) as u32,
        charging,
        full: state == 4,
        remaining: if charging { to_full } else { to_empty },
    })
}
