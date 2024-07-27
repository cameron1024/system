{
  lib,
  pkgs,
  machine,
  ...
}: let
  wallpapers = map (wp: wp pkgs) machine.wallpapers;
  allWallpapersString = lib.lists.foldr (a: b: "${a} ${b}") "" wallpapers;

  randomWallpaper = pkgs.writeShellScriptBin "randomWallpaper.sh" ''
    ALL_WALLPAPERS="${allWallpapersString}"
    ${builtins.readFile ./randomWallpaper.sh}
  '';
in {
  home.packages = with pkgs; [
    swww
    randomWallpaper
  ];

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # set the clear background even if the daemon is running
      "swww-daemon; ${randomWallpaper}/bin/randomWallpaper"
    ];
  };
}
