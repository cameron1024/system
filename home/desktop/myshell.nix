{
  pkgs,
  lib,
  config,
  ...
}: let
  # dmenu for the shell's launcher: `printf 'a\nb' | myshell-menu -p Pick`.
  myshell-menu = pkgs.rustPlatform.buildRustPackage {
    pname = "myshell-menu";
    version = "0.1.0";
    src = ../myshell/menu;
    cargoLock.lockFile = ../myshell/menu/Cargo.lock;
  };
in {
  config = lib.mkIf (pkgs.stdenv.isLinux && config.services'.desktop.enable) {
    home.packages = [
      myshell-menu
      # For the terminal too: the launcher's calculator has its own (from the devshell).
      pkgs.libqalculate
    ];
  };
}
