use futures::channel::mpsc::UnboundedSender;

use crate::bar_module::Module;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Command {
    ToggleBar,
    Activate(Module),
}

struct Shortcuts {
    sender: UnboundedSender<Command>,
}

#[zbus::interface(name = "org.myshell.Shell")]
impl Shortcuts {
    fn toggle_bar(&self) -> zbus::fdo::Result<()> {
        self.send(Command::ToggleBar)
    }

    fn activate(&self, module: &str) -> zbus::fdo::Result<()> {
        let module = match module {
            "clock" => Module::Clock,
            "power-profile" => Module::PowerProfile,
            "volume" => Module::Volume,
            _ => {
                return Err(zbus::fdo::Error::InvalidArgs(format!(
                    "unknown module: {module}"
                )));
            }
        };
        self.send(Command::Activate(module))
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
