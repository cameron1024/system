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
    cargo-duplicates

    wasm-tools

    evcxr
  ];

  programs.nushell.shellAliases = {
    r = "evcxr";
    cg = "cargo";
    nt = "cargo nextest run";
  };
}
