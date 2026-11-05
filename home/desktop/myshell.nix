{
  pkgs,
  lib,
  config,
  ...
}: let
  myshell = pkgs.callPackage ../myshell/package.nix {};
  # dmenu for the shell's launcher: `printf 'a\nb' | myshell-menu -p Pick`.
  myshell-menu = pkgs.rustPlatform.buildRustPackage {
    pname = "myshell-menu";
    version = "0.1.0";
    src = ../myshell/menu;
    cargoLock.lockFile = ../myshell/menu/Cargo.lock;
  };
in {
  config = lib.mkIf (pkgs.stdenv.isLinux && config.services'.desktop.enable) {
    systemd.user.startServices = "sd-switch";
    systemd.user.services.myshell = {
      Unit = {
        Description = "myshell Wayland shell";
        After = ["niri.service"];
        PartOf = ["niri.service"];
        Requisite = ["niri.service"];
      };
      Service = {
        ExecStart = lib.getExe myshell;
        Restart = "on-failure";
        RestartSec = 3;
        KillMode = "control-group";
        TimeoutStopSec = 10;
      };
      Install.WantedBy = ["niri.service"];
    };

    home.packages = [
      myshell
      myshell-menu
      # For the terminal too: the launcher's calculator has its own (from the devshell).
      pkgs.libqalculate
    ];
  };
}
