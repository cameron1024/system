use std::io;
use std::process::Stdio;
use std::time::Duration;

use async_process::Child;
use async_process::ChildStdout;
use async_process::Command;
use futures::Stream;
use futures::TryStreamExt;
use futures::future::Either;
use futures::future::select;
use futures::io::AsyncBufReadExt;
use futures::io::BufReader;

use super::DataSource;
use super::Result;

pub struct Volume;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct VolumeState {
    pub percent: u32,
    pub muted: bool,
}

impl DataSource for Volume {
    type Value = VolumeState;

    fn stream(self) -> impl Stream<Item = Result<VolumeState>> + Send + 'static {
        futures::stream::once(async {
            let (mut child, mut events) = subscribe().await?;
            Ok::<_, super::Error>(async_stream::stream! {
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
            })
        })
        .try_flatten()
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
    let percent = parse_percent(&output(&["get-sink-volume", "@DEFAULT_SINK@"]).await?)?;
    let mute = output(&["get-sink-mute", "@DEFAULT_SINK@"]).await?;
    let muted = match mute.trim() {
        "Mute: yes" => true,
        "Mute: no" => false,
        _ => return Err(io::Error::other(format!("invalid pactl mute output: {mute:?}")).into()),
    };
    Ok(VolumeState { percent, muted })
}

fn parse_percent(output: &str) -> io::Result<u32> {
    let invalid = || io::Error::other(format!("invalid pactl volume output: {output:?}"));
    let volume = output.trim().strip_prefix("Volume:").ok_or_else(invalid)?;
    // Channel names/counts vary; use the loudest channel, preserving amplification above 100%.
    let mut loudest = None;
    for percent in volume
        .split_whitespace()
        .filter_map(|token| token.strip_suffix('%'))
    {
        let percent = percent.parse::<u32>().map_err(|_| invalid())?;
        loudest = Some(loudest.unwrap_or(0).max(percent));
    }
    loudest.ok_or_else(invalid)
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
    fn parses_channels_and_amplification() {
        assert_eq!(
            parse_percent("Volume: mono: 0 / 0% / -inf dB\n").unwrap(),
            0
        );
        assert_eq!(
            parse_percent(
                "Volume: front-left: 32768 / 50% / -18.06 dB,   front-right: 81920 / 125% / 5.81 dB\n        balance 0.60\n",
            )
            .unwrap(),
            125,
        );
        for output in ["", "Volume: mono: 65536 / nope% / 0.00 dB", "Mute: no"] {
            assert!(parse_percent(output).is_err());
        }
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
