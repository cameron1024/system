use clap::Parser;
use inquire::Text;

#[derive(Debug, Parser)]
#[clap(rename_all = "kebab-case")]
enum Args {
    Init,
    Switch,
}

fn main() {
    let args = Args::parse();

    match args {
        Args::Init => {
            let file = dirs::config_dir().unwrap().join("system_config");
            let contents = match get_device_spec() {
                DeviceSpec::Macos => "sudo nix run nix-darwin -- switch --flake .",
                DeviceSpec::Mini => "sudo nixos-rebuild switch --flake .#mini",
                DeviceSpec::Thinkpad => "sudo nixos-rebuild switch --flake .#thinkpad",
            };

            std::fs::write(&file, contents.as_bytes()).unwrap();
        }
        Args::Switch => panic!(),
    }
}

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
