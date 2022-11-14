{ pkgs, ... }:

{
  home.packages = with pkgs; [
    rustup
    gcc
    llvmPackages.bintools-unwrapped
    cmake
    glibc
    cargo-cache
    cargo-nextest
    cargo-udeps
    cargo-edit
    bacon
    rust-script
    rust-analyzer

    (import ../../../rust_packages/cargo-duplicates.nix { inherit pkgs; })
  ];
}
