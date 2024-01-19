use std::{path::PathBuf, process::Command};

use rand::{seq::SliceRandom, thread_rng};

pub fn random_wallpaper(wallpapers: &[PathBuf]) {
    let wallpaper = wallpapers.choose(&mut thread_rng()).unwrap();

    Command::new("swww")
        .arg("img")
        .arg(wallpaper)
        .arg("--transition-step")
        .arg("1")
        .arg("--transition-duration")
        .arg("1")
        .arg("--transition-fps")
        .arg("60")
        .arg("--transition-type")
        .arg("any")
        .arg("--transition-bezier")
        .arg("0.17,0.67,0.83,0.67")
        .spawn()
        .unwrap();
}
