use clap::Parser;

mod battery;

#[derive(Debug, Parser)]
enum Args {
    Battery,
}

fn main() {
    let args = Args::parse();

    match args {
        Args::Battery => battery::battery(),
    }
}
