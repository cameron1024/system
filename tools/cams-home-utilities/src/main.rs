use std::path::PathBuf;

use clap::Parser;

mod battery;
mod wallpaper;

#[derive(Debug, Parser)]
enum Args {
    Battery,
    RandomWallpaper { wallpapers: Vec<PathBuf> },
    // Catppuccinify { path: PathBuf },
}

fn main() {
    let args = Args::parse();

    match args {
        Args::Battery => battery::battery(),
        Args::RandomWallpaper { wallpapers } => wallpaper::random_wallpaper(&wallpapers),
    }
}
