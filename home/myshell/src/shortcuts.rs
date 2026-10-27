use futures::channel::mpsc::UnboundedSender;

use crate::bar_module::Module;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Command {
    ToggleBar,
    ToggleLauncher,
    Activate(Module),
    Adjust(Module, i32),
}

struct Shortcuts {
    sender: UnboundedSender<Command>,
}

#[zbus::interface(name = "org.myshell.Shell")]
impl Shortcuts {
    fn toggle_bar(&self) -> zbus::fdo::Result<()> {
        self.send(Command::ToggleBar)
    }

    /// On the focused display.
    fn toggle_launcher(&self) -> zbus::fdo::Result<()> {
        self.send(Command::ToggleLauncher)
    }

    fn activate(&self, module: &str) -> zbus::fdo::Result<()> {
        self.send(Command::Activate(parse(module)?))
    }

    fn adjust(&self, module: &str, steps: i32) -> zbus::fdo::Result<()> {
        self.send(Command::Adjust(parse(module)?, steps))
    }
}

impl Shortcuts {
    fn send(&self, command: Command) -> zbus::fdo::Result<()> {
        self.sender
            .unbounded_send(command)
            .map_err(|error| zbus::fdo::Error::Failed(error.to_string()))
    }
}

fn parse(module: &str) -> zbus::fdo::Result<Module> {
    Module::ALL
        .into_iter()
        .find(|candidate| candidate.name() == module)
        .ok_or_else(|| zbus::fdo::Error::InvalidArgs(format!("unknown module: {module}")))
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
