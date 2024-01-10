use std::{io::ErrorKind, path::PathBuf, process::ExitCode};

use clap::Parser;
use inquire::Text;
use serde::{Deserialize, Serialize};

#[derive(Debug, Parser)]
#[clap(rename_all = "kebab-case")]
enum Args {
    Init,
    Print,
    Switch,
    Clear,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
struct Config {
    spec: DeviceSpec,
    switch_script: String,
}

fn get_path() -> PathBuf {
    dirs::config_dir().unwrap().join("system_config")
}
fn main() -> ExitCode {
    let args = Args::parse();

    match args {
        Args::Init => {
            let path = get_path();
            let spec = get_device_spec();
            let switch_script = match spec {
                DeviceSpec::Macos => "sudo nix run nix-darwin -- switch --flake .",
                DeviceSpec::Mini => "sudo nixos-rebuild switch --flake .#mini",
                DeviceSpec::Thinkpad => "sudo nixos-rebuild switch --flake .#thinkpad",
            }
            .to_string();

            let contents = toml::to_string(&Config {
                spec,
                switch_script,
            })
            .unwrap();

            std::fs::write(&path, contents.as_bytes()).unwrap();
        }
        Args::Print => {
            let path = get_path();
            let text = match std::fs::read_to_string(&path) {
                Ok(s) => s,
                Err(e) if e.kind() == ErrorKind::NotFound => {
                    eprintln!("not initialized - call `device-manager init`");
                    return ExitCode::FAILURE;
                }
                Err(e) => panic!("{e}"),
            };
            println!("{text}");
        }
        Args::Switch => {
            let path = get_path();
            let text = match std::fs::read_to_string(&path) {
                Ok(s) => s,
                Err(e) if e.kind() == ErrorKind::NotFound => {
                    eprintln!("not initialized - call `device-manager init`");
                    return ExitCode::FAILURE;
                }
                Err(e) => panic!("{e}"),
            };
            let config: Config = toml::from_str(&text).unwrap();
            println!("{}", config.switch_script);
        }
        Args::Clear => {
            let path = get_path();
            std::fs::remove_file(&path).unwrap();
        }
    }

    ExitCode::SUCCESS
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
enum DeviceSpec {
    Macos,
    Mini,
    Thinkpad,
}

fn get_device_spec() -> DeviceSpec {
    match std::env::consts::OS {
        "macos" => DeviceSpec::Macos,
        "linux" => get_linux_spec(),
        other => panic!("unknown OS: {other}"),
    }
}

fn get_linux_spec() -> DeviceSpec {
    let text = Text::new("Device Name:")
        .prompt()
        .expect("operation cancelled");

    match text.as_ref() {
        "mini" => DeviceSpec::Mini,
        "thinkpad" => DeviceSpec::Thinkpad,
        other => panic!("unknown device: {other}"),
    }
}
