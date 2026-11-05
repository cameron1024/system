use std::env;
use std::path::PathBuf;

fn main() {
    println!("cargo::rerun-if-changed=build.rs");
    println!("cargo::rustc-check-cfg=cfg(release_profile)");

    // PROFILE reports "release" for custom profiles too; OUT_DIR preserves their actual name.
    let out_dir = PathBuf::from(env::var_os("OUT_DIR").unwrap());
    let profile = out_dir.ancestors().nth(3).unwrap().file_name().unwrap();
    if profile == "release" {
        println!("cargo::rustc-cfg=release_profile");
    }
}
