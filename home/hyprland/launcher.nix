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
        "SUPER, space, exec, tofi-drun"
      ];
    };
    programs.tofi = {
      enable = true;
      settings = {
        width = "100%";
        height = "100%";
        border-width = "0";
        outline-width = "0";
        font = "Fira Sans";
        anchor = "center";
        selection-color = "#A7C080";
      };
    };

    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
    };
  };
}
