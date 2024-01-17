use std::{path::PathBuf, process::Command};

use rand::{seq::SliceRandom, thread_rng};

pub fn random_wallpaper(wallpapers: &[PathBuf]) {
    let wallpaper = wallpapers.choose(&mut thread_rng()).unwrap();

    let cmd = format!(
        "swww img {} --transition-step 1 --transition-fps 60 --transition-type random",
        wallpaper.to_str().unwrap()
    );

    Command::new(cmd).spawn().unwrap();
}
