{ pkgs, username, ... }:

let
  themeFile = pkgs.writeTextFile {
    name = "catppuccin.rasi";
    text = builtins.readFile ./theme.rasi;
  };
in

{
  home-manager.users.${username} = {
    home.packages = with pkgs; [
      oranchelo-icon-theme
    ];

    programs.rofi = {
      enable = true;
      theme = "${themeFile}";
      plugins = with pkgs; [
        rofi-power-menu
      ];
    };

    wayland.windowManager.hyprland.settings = {
      bind = [
        # "SUPER SHIFT, space, exec, rofi -show combi"
      ];
    };
  };
}
