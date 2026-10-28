//! dmenu for myshell: shows the options on stdin (one per line) in the shell's launcher, and
//! prints the one chosen (or what was typed, if nothing matched). Exits with 1 if the launcher is
//! closed without a choice, as dmenu does.
//!
//! e.g. `printf 'yes\nno' | myshell-menu -p Continue?`

use std::io::BufRead;
use std::process::ExitCode;

use clap::Parser;

/// Choose one of the options on stdin (one per line) in myshell's launcher.
#[derive(Parser)]
#[command(version)]
struct Args {
    /// Shown as the launcher's title.
    #[arg(short, long)]
    prompt: Option<String>,
    /// dmenu's case-insensitive flag, accepted for compatibility: matching is already smart-case.
    #[arg(short = 'i', hide = true)]
    _case_insensitive: bool,
}

fn main() -> ExitCode {
    let args = Args::parse();
    let options: Vec<String> = std::io::stdin()
        .lock()
        .lines()
        .map_while(Result::ok)
        .filter(|line| !line.is_empty())
        .collect();
    // The shell takes an empty prompt as none.
    match choose(args.prompt.as_deref().unwrap_or_default(), &options) {
        Ok(choice) => {
            println!("{choice}");
            ExitCode::SUCCESS
        }
        Err(zbus::Error::MethodError(name, _, _)) if name.as_str().ends_with(".Failed") => {
            ExitCode::FAILURE
        }
        Err(error) => {
            eprintln!("myshell-menu: {error}");
            ExitCode::FAILURE
        }
    }
}

/// Waits (with no timeout) until a choice is made or the launcher closes.
fn choose(prompt: &str, options: &[String]) -> zbus::Result<String> {
    let reply = zbus::blocking::Connection::session()?.call_method(
        Some("org.myshell.Shell"),
        "/org/myshell/Shell",
        Some("org.myshell.Shell"),
        "Menu",
        &(prompt, options),
    )?;
    reply.body().deserialize()
}
