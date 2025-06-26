{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
with lib; {
  imports = [
    ../hyprland/launcher.nix
    ../hyprland/bar
    ../hyprland/wallpaper
    ../hyprland/notifications.nix
    ../hyprland/hardware.nix
    ../desktop
  ];

  options.programs'.niri = {
    extraConfig = mkOption {
      type = types.str;
      description = "Extra .kdl config to append to the generated config";
      default = "";
    };
  };

  config = mkIf (osConfig != null && osConfig.programs'.niri.enable) {
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
            mode "${toString resolution.width}x${toString resolution.height}@${toString refreshRate}"
            scale ${toString scale}
            transform "normal"
            position x=${toString position.x} y=${toString position.y}
        }
      '';
      displaysConfig = map formatDisplay osConfig.services'.desktop.displays;
    in
      /*
      kdl
      */
      ''
        ${builtins.readFile ./config.kdl}
        ${lib.strings.concatMapStrings (x: x + "\n") displaysConfig}


        ${config.programs'.niri.extraConfig}
      '';
  };
}
