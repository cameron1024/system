{
  machine,
  lib,
  pkgs,
  inputs,
  ...
}: {
  config = lib.mkIf machine.linux {
    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER, space, exec, rofi -show drun"
        "ALT, Tab, exec, nix run /home/cameron/projects/hyprtab#gui"
      ];
      #
      # bindr = [
      #   "ALT, ALT, exec, kitty"
      # ];
    };

    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
    };
  };
}
