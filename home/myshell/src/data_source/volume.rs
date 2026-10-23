use std::io;
use std::process::Stdio;
use std::time::Duration;

use async_process::Child;
use async_process::ChildStdout;
use async_process::Command;
use futures::Stream;

use futures::future::Either;
use futures::future::select;
use futures::io::AsyncBufReadExt;
use futures::io::BufReader;

use super::Data;
use super::DataSource;
use super::Result;
use crate::command::command;

pub struct Volume;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct VolumeState {
    pub percent: u32,
    pub muted: bool,
    pub output: String,
    pub output_name: String,
}

impl Data<Volume> {
    pub fn toggle_mute(&mut self, cx: &mut gpui::Context<Self>) {
        let Some(mut target) = self.state.target.clone() else {
            return;
        };
        target.muted = !target.muted;
        self.request(
            target.clone(),
            async move {
                command(
                    "pactl",
                    &[
                        "set-sink-mute",
                        &target.output_name,
                        if target.muted { "1" } else { "0" },
                    ],
                )
                .await?;
                Ok(())
            },
            cx,
        );
    }

    pub fn change_volume(&mut self, steps: i32, cx: &mut gpui::Context<Self>) {
        let Some(mut target) = self.state.target.clone() else {
            return;
        };
        target.percent = target
            .percent
            .saturating_add_signed(steps.saturating_mul(5))
            .min(100);
        self.request(
            target.clone(),
            async move {
                command(
                    "pactl",
                    &[
                        "set-sink-volume",
                        &target.output_name,
                        &format!("{}%", target.percent),
                    ],
                )
                .await?;
                Ok(())
            },
            cx,
        );
    }
}

impl DataSource for Volume {
    type Value = VolumeState;

    fn reconcile_target(target: &mut Self::Value, known: &Self::Value) -> bool {
        if target.output_name != known.output_name {
            return false;
        }
        target.output.clone_from(&known.output);
        true
    }

    fn stream(self) -> impl Stream<Item = Result<VolumeState>> + Send + 'static {
        async_stream::stream! {
            loop {
                match subscribe().await {
                    Ok((mut child, mut events)) => {
                        yield query().await;
                        let mut line = String::new();
                        loop {
                            line.clear();
                            if let Err(error) = read_event(&mut child, &mut events, &mut line).await {
                                yield Err(error);
                                break;
                            }
                            if affects_volume(&line) {
                                yield query().await;
                            }
                        }
                    }
                    Err(error) => yield Err(error),
                }
                // The audio server restarts (e.g. on a system switch); a timer runs only while
                // disconnected.
                async_io::Timer::after(Duration::from_secs(1)).await;
            }
        }
    }
}

fn pactl() -> Command {
    let mut command = Command::new("pactl");
    command.env("LC_ALL", "C").kill_on_drop(true);
    command
}

async fn subscribe() -> Result<(Child, BufReader<ChildStdout>)> {
    let mut child = pactl()
        .arg("subscribe")
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()?;
    let mut events = BufReader::new(child.stdout.take().unwrap());
    // pactl has no subscription acknowledgement. Read-only probes generate client
    // events; seeing any event proves readiness before taking the initial snapshot.
    let ready = async {
        let mut line = String::new();
        loop {
            output(&["info"]).await?;
            let event = read_event(&mut child, &mut events, &mut line);
            let retry = async_io::Timer::after(Duration::from_millis(50));
            futures::pin_mut!(event, retry);
            if let Either::Left((result, _)) = select(event, retry).await {
                return result;
            }
        }
    };
    let deadline = async_io::Timer::after(Duration::from_secs(3));
    {
        futures::pin_mut!(ready, deadline);
        match select(ready, deadline).await {
            Either::Left((result, _)) => result?,
            Either::Right(_) => {
                return Err(io::Error::new(
                    io::ErrorKind::TimedOut,
                    "pactl subscribe did not become ready within 3 seconds",
                )
                .into());
            }
        }
    }
    Ok((child, events))
}

async fn read_event(
    child: &mut Child,
    events: &mut BufReader<ChildStdout>,
    line: &mut String,
) -> Result<()> {
    if events.read_line(line).await? == 0 {
        // Don't await exit: a child can close stdout without terminating.
        let status = child.try_status()?;
        return Err(io::Error::new(
            io::ErrorKind::UnexpectedEof,
            match status {
                Some(status) => format!("pactl subscribe ended with {status}"),
                None => "pactl subscribe closed stdout unexpectedly".into(),
            },
        )
        .into());
    }
    Ok(())
}

async fn output(args: &[&str]) -> Result<String> {
    let output = pactl().args(args).output().await?;
    if !output.status.success() {
        return Err(io::Error::other(format!(
            "pactl {} failed with {}: {}",
            args.join(" "),
            output.status,
            String::from_utf8_lossy(&output.stderr).trim(),
        ))
        .into());
    }
    Ok(String::from_utf8(output.stdout)?)
}

async fn query() -> Result<VolumeState> {
    let default = output(&["get-default-sink"]).await?;
    let sinks = output(&["--format=json", "list", "sinks"]).await?;
    // A concurrent default change generates a server event, prompting another snapshot.
    Ok(parse_sink(default.trim(), &sinks)?)
}

fn parse_sink(default: &str, output: &str) -> io::Result<VolumeState> {
    let invalid = || io::Error::other("invalid pactl sink data or missing default sink");
    let sinks: serde_json::Value = serde_json::from_str(output)
        .map_err(|error| io::Error::new(io::ErrorKind::InvalidData, error))?;
    let sink = sinks
        .as_array()
        .ok_or_else(invalid)?
        .iter()
        .find(|sink| sink["name"].as_str() == Some(default))
        .ok_or_else(invalid)?;
    let muted = sink["mute"].as_bool().ok_or_else(invalid)?;
    let channels = sink["volume"].as_object().ok_or_else(invalid)?;
    // PulseAudio's normal volume is 65536. Round just like pactl's text output,
    // using the loudest channel and preserving amplification above 100%.
    let mut loudest = None;
    for channel in channels.values() {
        let value = channel["value"].as_u64().ok_or_else(invalid)?;
        let percent = value
            .checked_mul(100)
            .and_then(|value| value.checked_add(32768))
            .and_then(|value| u32::try_from(value / 65536).ok())
            .ok_or_else(invalid)?;
        loudest = Some(loudest.unwrap_or(0).max(percent));
    }
    Ok(VolumeState {
        percent: loudest.ok_or_else(invalid)?,
        muted,
        output_name: default.to_owned(),
        output: sink["description"]
            .as_str()
            .filter(|description| !description.trim().is_empty())
            .unwrap_or(default)
            .to_owned(),
    })
}

fn affects_volume(event: &str) -> bool {
    event.split_once(" on ").is_some_and(|(_, object)| {
        matches!(object.split_whitespace().next(), Some("sink" | "server"))
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn selects_default_sink_with_coherent_state() {
        let sinks = r#"[
            {"name":"speakers","description":"Desk speakers","mute":false,
             "volume":{"front-left":{"value":32768},"front-right":{"value":81920}}},
            {"name":"headphones","description":"USB headphones","mute":true,
             "volume":{"mono":{"value":0}}}
        ]"#;
        assert_eq!(
            parse_sink("speakers", sinks).unwrap(),
            VolumeState {
                percent: 125,
                muted: false,
                output: "Desk speakers".into(),
                output_name: "speakers".into()
            }
        );
        assert_eq!(
            parse_sink("headphones", sinks).unwrap(),
            VolumeState {
                percent: 0,
                muted: true,
                output: "USB headphones".into(),
                output_name: "headphones".into()
            }
        );
        assert!(parse_sink("missing", sinks).is_err());
    }

    #[test]
    fn falls_back_to_name_and_rounds_volume() {
        for description in ["", r#", "description":null"#, r#", "description":"""#] {
            let sinks = format!(
                r#"[{{"name":"default","mute":false,"volume":{{"mono":{{"value":65535}}}}{description}}}]"#
            );
            assert_eq!(
                parse_sink("default", &sinks).unwrap(),
                VolumeState {
                    percent: 100,
                    muted: false,
                    output: "default".into(),
                    output_name: "default".into()
                }
            );
        }
    }

    #[test]
    fn rejects_invalid_sink_data() {
        for sinks in [
            "",
            "not json",
            "{}",
            "[]",
            r#"[{"name":"default","volume":{"mono":{"value":65536}}}]"#,
            r#"[{"name":"default","mute":"yes","volume":{"mono":{"value":65536}}}]"#,
            r#"[{"name":"default","mute":false,"volume":{}}]"#,
            r#"[{"name":"default","mute":false,"volume":{"mono":{"value":"100%"}}}]"#,
            r#"[{"name":"default","mute":false,"volume":{"mono":{"value":-1}}}]"#,
            r#"[{"name":"default","mute":false,"volume":{"mono":{"value":18446744073709551615}}}]"#,
        ] {
            assert!(parse_sink("default", sinks).is_err(), "{sinks}");
        }
    }

    #[test]
    fn reconciles_description_without_changing_optimistic_controls() {
        let mut target = VolumeState {
            percent: 75,
            muted: true,
            output: "Old description".into(),
            output_name: "speakers".into(),
        };
        let known = VolumeState {
            percent: 50,
            muted: false,
            output: "New description".into(),
            output_name: "speakers".into(),
        };
        assert!(Volume::reconcile_target(&mut target, &known));
        assert_eq!(target.output, known.output);
        assert_eq!(target.output_name, "speakers");
        assert_eq!(target.percent, 75);
        assert!(target.muted);
        let confirmed = VolumeState {
            percent: 75,
            muted: true,
            ..known
        };
        assert_eq!(target, confirmed);
    }

    #[test]
    fn rejects_target_for_different_output_without_mutating_it() {
        let mut target = VolumeState {
            percent: 75,
            muted: true,
            output: "Shared description".into(),
            output_name: "speakers".into(),
        };
        let original = target.clone();
        let known = VolumeState {
            output_name: "headphones".into(),
            ..target.clone()
        };
        assert!(!Volume::reconcile_target(&mut target, &known));
        assert_eq!(target, original);
    }

    #[test]
    fn filters_subscription_events() {
        assert!(affects_volume("Event 'change' on sink #42\n"));
        assert!(affects_volume("Event 'change' on server #4294967295\n"));
        assert!(affects_volume("Event 'remove' on sink #42\n"));
        for object in ["sink-input", "source", "source-output", "client", "card"] {
            assert!(!affects_volume(&format!(
                "Event 'change' on {object} #42\n"
            )));
        }
        assert!(!affects_volume(""));
    }
}
