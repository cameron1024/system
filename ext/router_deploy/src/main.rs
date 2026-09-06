mod apply;
mod config;
mod secrets;
mod ssh;

use anyhow::Result;
use clap::{Parser, Subcommand};

use crate::{config::Config, ssh::Ssh};

/// Declarative OpenWrt router deployment.
///
/// The desired configuration is read as JSON from stdin (the nix wrapper
/// pipes in the module-generated config file).
#[derive(Parser)]
#[command(name = "router-deploy", version)]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// Parse the config from stdin and print it (secret references stay
    /// unresolved, so nothing sensitive is printed)
    Config,
    /// Resolve secrets, apply the full config to the router, and restart
    /// the affected services (no reboot)
    Apply,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let config = Config::from_stdin()?;

    match cli.command {
        Command::Config => println!("{config:#?}"),
        Command::Apply => {
            let ssh = Ssh::new(&config.host);
            apply::apply(&config, &ssh)?;
        }
    }

    Ok(())
}
