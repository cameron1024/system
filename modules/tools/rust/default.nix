{ pkgs, lib, isDarwin, username, ... }:

with lib; {
  home-manager.users.${username} = {
    home.packages = with pkgs; [
      rustup

      bacon

      cargo-cache
      cargo-nextest
      cargo-udeps
      cargo-edit
      cargo-bloat
      cargo-duplicates

      wasm-tools

      evcxr
    ] ++ optionals (!isDarwin) [
      gcc
      llvmPackages.bintools-unwrapped
      cmake
      ninja
    ];

    programs.nushell.shellAliases = {
      r = "evcxr";
      cg = "cargo";
      nt = "cargo nextest run";
    };
  };
}
