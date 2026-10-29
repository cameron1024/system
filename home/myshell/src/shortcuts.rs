use futures::channel::mpsc::UnboundedSender;
use futures::channel::oneshot;

use crate::bar_module::Module;
use crate::launcher::Menu;
use crate::launcher::Mode;

#[derive(Debug)]
pub enum Command {
    ToggleBar,
    /// Toggles the launcher, or (if given a mode and open in another) switches to that mode.
    ToggleLauncher(Option<Mode>),
    /// Shows options in the launcher on the focused display, like dmenu.
    Menu(Menu),
    Activate(Module),
    Adjust(Module, i32),
    ToggleDoNotDisturb,
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
        self.send(Command::ToggleLauncher(None))
    }

    /// On the focused display, in `mode` (by name, e.g. "emoji").
    fn toggle_launcher_mode(&self, mode: &str) -> zbus::fdo::Result<()> {
        let mode = (Mode::SELECTABLE.into_iter())
            .find(|candidate| candidate.name().eq_ignore_ascii_case(mode))
            .ok_or_else(|| zbus::fdo::Error::InvalidArgs(format!("unknown mode: {mode}")))?;
        self.send(Command::ToggleLauncher(Some(mode)))
    }

    /// Replies with the chosen option (or what was typed, if none matched), once chosen. Fails
    /// if the launcher closes without a choice. `prompt` titles it, unless empty.
    async fn menu(&self, prompt: String, options: Vec<String>) -> zbus::fdo::Result<String> {
        let (reply, choice) = oneshot::channel();
        let prompt = (!prompt.is_empty()).then_some(prompt);
        self.send(Command::Menu(Menu {
            prompt,
            options,
            reply,
        }))?;
        choice
            .await
            .map_err(|_| zbus::fdo::Error::Failed("cancelled".into()))
    }

    fn toggle_do_not_disturb(&self) -> zbus::fdo::Result<()> {
        self.send(Command::ToggleDoNotDisturb)
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
