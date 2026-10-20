use futures::channel::mpsc::UnboundedSender;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Command {
    ToggleBar,
    ToggleForeground,
}

struct Shortcuts {
    sender: UnboundedSender<Command>,
}

#[zbus::interface(name = "org.myshell.Shell")]
impl Shortcuts {
    fn toggle_bar(&self) -> zbus::fdo::Result<()> {
        self.send(Command::ToggleBar)
    }

    fn toggle_foreground(&self) -> zbus::fdo::Result<()> {
        self.send(Command::ToggleForeground)
    }
}

impl Shortcuts {
    fn send(&self, command: Command) -> zbus::fdo::Result<()> {
        self.sender
            .unbounded_send(command)
            .map_err(|error| zbus::fdo::Error::Failed(error.to_string()))
    }
}

/// Keep the returned connection alive while receiving commands on the UI thread.
pub async fn listen(
    sender: UnboundedSender<Command>,
) -> crate::data_source::Result<zbus::Connection> {
    Ok(zbus::connection::Builder::session()?
        .name("org.myshell.Shell")?
        .serve_at("/org/myshell/Shell", Shortcuts { sender })?
        .build()
        .await?)
}
