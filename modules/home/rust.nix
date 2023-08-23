{ pkgs, ... }:
let
  de-init = pkgs.writeShellScriptBin "de-init" ''
    echo "use flake" > .envrc
    echo "/.direnv/" >> .gitignore
    git add -A
    direnv allow
  '';
in

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

    de-init
  ];

  programs.fish.shellAbbrs = {
    r = "evcxr";
    cg = "cargo";
    nt = "cargo nextest run";
  };
}
