use futures::Stream;
use futures::StreamExt;
use futures::TryStreamExt;
use zbus::fdo::PropertiesProxy;
use zbus::proxy::CacheProperties;

use super::DataSource;
use super::Result;

const INTERFACE: &str = "net.hadess.PowerProfiles";
const PROPERTY: &str = "ActiveProfile";

pub struct PowerProfile;

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Profile {
    PowerSaver,
    Balanced,
    Performance,
    Unknown(String),
}

impl From<String> for Profile {
    fn from(value: String) -> Self {
        match value.as_str() {
            "power-saver" => Self::PowerSaver,
            "balanced" => Self::Balanced,
            "performance" => Self::Performance,
            _ => Self::Unknown(value),
        }
    }
}

impl DataSource for PowerProfile {
    type Value = Profile;

    fn stream(self) -> impl Stream<Item = Result<Profile>> + Send + 'static {
        futures::stream::once(async {
            let connection = zbus::Connection::system().await?;
            let properties = PropertiesProxy::builder(&connection)
                .destination(INTERFACE)?
                .path("/net/hadess/PowerProfiles")?
                .cache_properties(CacheProperties::No)
                .build()
                .await?;

            // Subscribe before reading, including owner changes so restarts refresh the value.
            let changes = properties.receive_properties_changed().await?;
            let owners = properties.inner().receive_owner_changed().await?;
            let changes = changes.map(|signal| -> Result<bool> {
                let args = signal.args()?;
                Ok(args.interface_name().as_str() == INTERFACE
                    && (args.changed_properties().contains_key(PROPERTY)
                        || args.invalidated_properties().contains(&PROPERTY)))
            });
            let owners = owners.map(|owner| -> Result<bool> {
                owner.ok_or_else(|| {
                    std::io::Error::new(
                        std::io::ErrorKind::NotConnected,
                        "power profile daemon unavailable",
                    )
                })?;
                Ok(true)
            });
            let mut updates =
                futures::stream::iter([Ok(true)]).chain(futures::stream::select(changes, owners));

            Ok::<_, super::Error>(async_stream::stream! {
                let mut previous = None;
                while let Some(update) = updates.next().await {
                    let result: Result<Profile> = match update {
                        Ok(false) => continue,
                        Ok(true) => async {
                            // Read current state rather than replaying potentially stale signals.
                            let value = properties.get(INTERFACE.try_into()?, PROPERTY).await?;
                            Ok(Profile::from(String::try_from(value)?))
                        }.await,
                        Err(error) => Err(error),
                    };
                    match &result {
                        Ok(profile) if previous.as_ref() == Some(profile) => continue,
                        Ok(profile) => previous = Some(profile.clone()),
                        Err(_) => previous = None,
                    }
                    yield result;
                }
                yield Err(std::io::Error::new(
                    std::io::ErrorKind::BrokenPipe,
                    "power profile signal stream closed",
                ).into());
            })
        })
        .try_flatten()
    }
}
