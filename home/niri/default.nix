{
  machine,
  pkgs,
  lib,
  ...
}:
with lib; {
  imports = [
    ../hyprland/launcher.nix
    ../hyprland/bar
    ../hyprland/wallpaper
    ../hyprland/lock
    ../hyprland/notifications.nix
    ../hyprland/hardware.nix
    ../desktop
  ];


  config = mkIf machine.linux {
    home.packages = with pkgs; [
      wl-clipboard
      xwayland-satellite
    ];

    home.pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
    };

    xdg.configFile."niri/config.kdl".text = let
      formatDisplay = {
        name,
        resolution,
        position,
        refreshRate,
        scale,
        ...
      }:
      /*
      kdl
      */
      ''
        output "${name}" {
            mode "${resolution}@${toString refreshRate}"
            scale ${toString scale}
            transform "normal"
            position x=${toString position.x} y=${toString position.y}
        }
      '';
      displays = map formatDisplay machine.displays;
    in ''
      ${builtins.readFile ./config.kdl}
      ${lib.strings.concatMapStrings (x: x + "\n") displays}
    '';
  };
}
