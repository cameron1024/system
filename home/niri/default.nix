{
  pkgs,
  lib,
  config,
  nixosConfig,
  inputs,
  ...
}:
with lib; {
  imports = [
    # inputs.dank-material-shell.homeModules.dankMaterialShell
    inputs.niri.homeModules.niri
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

  config = mkIf (pkgs.stdenv.isLinux && (nixosConfig.programs'.niri.enable or false)) {
    services'.desktop.enable = true;
    home.packages = with pkgs; [
      wl-clipboard
      xwayland-satellite
      material-icons
    ];

    home.pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
    };

    # programs.dankMaterialShell.enable = true;
    # programs.dankMaterialShell.enableSystemd = true;
    # programs.dankMaterialShell.enableKeybinds = false;

    programs.niri.config = let
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
      displaysConfig = map formatDisplay nixosConfig.services'.desktop.displays or [];
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
