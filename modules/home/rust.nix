{ pkgs, ... }:

{
  home.packages = with pkgs; [
    rustup
    gcc
    llvmPackages.bintools-unwrapped
    cmake
    glibc
    ninja

    rust-analyzer
    bacon

    cargo-cache
    cargo-nextest
    cargo-udeps
    cargo-edit
    (import ../../rust_packages/cargo-duplicates.nix { inherit pkgs; })
  ];
}
