{
  lib,
  pkgs,
  ...
}: let
  # TODO(cameron): fix
  wallpapers = map (wp: wp pkgs) [];
  allWallpapersString = lib.lists.foldr (a: b: "${a} ${b}") "" wallpapers;

  randomWallpaper = pkgs.writeShellScriptBin "randomWallpaper.sh" ''
    ALL_WALLPAPERS="${allWallpapersString}"
    ${builtins.readFile ./randomWallpaper.sh}
  '';
in {
  home.packages = lib.mkIf pkgs.stdenv.isLinux [
    pkgs.swww
    randomWallpaper
  ];

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # set the clear background even if the daemon is running
      "swww-daemon; ${randomWallpaper}/bin/randomWallpaper"
    ];
  };

  systemd.user.timers."randomize-wallpaper" = {
    Unit.Description = "Randomize wallpaper";
    Timer = {
      Unit = "randomize-wallpaper";
      OnCalendar = "*:0/15";
    };
    Install.WantedBy = ["timers.target"];
  };

  systemd.user.services."randomize-wallpaper" = {
    Unit = {
      Description = "Randomize wallpaper";
      After = ["multi-user.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = ''
        ${randomWallpaper}/bin/randomWallpaper.sh
      '';
    };
    Install.WantedBy = ["default.target"];
  };
}
