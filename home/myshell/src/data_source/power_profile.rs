use futures::Stream;
use futures::StreamExt;
use futures::TryStreamExt;

use super::Data;
use super::DataSource;
use super::Result;
use super::watch_properties;
use crate::command::command;

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

impl Profile {
    fn next(&self) -> Self {
        match self {
            Self::PowerSaver => Self::Balanced,
            Self::Balanced => Self::Performance,
            Self::Performance | Self::Unknown(_) => Self::PowerSaver,
        }
    }

    fn as_str(&self) -> &str {
        match self {
            Self::PowerSaver => "power-saver",
            Self::Balanced => "balanced",
            Self::Performance => "performance",
            Self::Unknown(name) => name,
        }
    }
}

impl Data<PowerProfile> {
    pub fn cycle(&mut self, cx: &mut gpui::Context<Self>) {
        let Some(current) = self.state.target.as_ref() else {
            return;
        };
        let target = current.next();
        self.request(
            target.clone(),
            async move {
                command("powerprofilesctl", &["set", target.as_str()]).await?;
                Ok(())
            },
            cx,
        );
    }
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
            let (properties, updates) = watch_properties(
                INTERFACE,
                "/net/hadess/PowerProfiles",
                INTERFACE,
                &[PROPERTY],
            )
            .await?;
            Ok::<_, super::Error>(async_stream::stream! {
                futures::pin_mut!(updates);
                let mut previous = None;
                while let Some(update) = updates.next().await {
                    let result: Result<Profile> = match update {
                        Ok(()) => async {
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
