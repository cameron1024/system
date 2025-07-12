{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.programs'.rofi.enable = mkEnableOption "rofi";
  config = lib.mkIf config.programs'.rofi.enable {
    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER, space, exec, rofi -show drun"
      ];
    };

    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      cycle = true;
      font = "Fira Code NerdFont";
      location = "left";
      terminal = "kitty";
      theme = ./style.rasi;

      plugins = with pkgs; [
        rofimoji
        rofi-power-menu
      ];
    };
  };
}
