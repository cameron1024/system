{ pkgs, ... }:




{
  home.packages = with pkgs; [
    rustup
    gcc
    llvmPackages.bintools-unwrapped
    cmake
    glibc
    ninja

    # rust-analyzer

    # (rust-analyzer.overrideAttrs (oldAttrs: { 
    #   RUSTC_FLAGS = "-Ctarget-cpu=native";
    # }))
    bacon

    cargo-cache
    cargo-nextest
    cargo-udeps
    cargo-edit
    cargo-bloat
    (import ../../rust_packages/cargo-duplicates.nix { inherit pkgs; })

    wasm-tools

    evcxr
  ];

  programs.fish.shellAbbrs = {
    r = "evcxr";
    cg = "cargo";
    nt = "cargo nextest run";
  };
}
