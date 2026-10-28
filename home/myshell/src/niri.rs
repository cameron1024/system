//! niri's IPC, for what Wayland doesn't tell clients.

use futures::AsyncBufReadExt;
use futures::AsyncWriteExt;

/// The focused output's name, e.g. "DP-2" (with focus-follows-mouse, the one with the pointer).
/// None if niri isn't running, or on any failure.
pub async fn focused_output() -> Option<String> {
    let path = std::env::var_os("NIRI_SOCKET")?;
    let stream = async_io::Async::<std::os::unix::net::UnixStream>::connect(path)
        .await
        .ok()?;
    (&stream).write_all(b"\"FocusedOutput\"\n").await.ok()?;
    let mut reply = String::new();
    futures::io::BufReader::new(&stream)
        .read_line(&mut reply)
        .await
        .ok()?;
    let reply: serde_json::Value = serde_json::from_str(&reply).ok()?;
    Some(reply["Ok"]["FocusedOutput"]["name"].as_str()?.to_owned())
}
