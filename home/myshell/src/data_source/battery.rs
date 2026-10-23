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
                &["Percentage", "State"],
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
    Ok(BatteryState {
        percent: percent.round().clamp(0., 100.) as u32,
        // UPower: 1 = charging, 2 = discharging, 4 = fully charged, 5 = pending charge, ...
        charging: state == 1,
    })
}
