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
      cycle = true;
      font = "Fira Code";
      terminal = "wezterm";
      theme = "${themeFile}";
      plugins = with pkgs; [
        rofi-calc
      ];
    };

    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER, space, exec, rofi -show drun"
      ];
    };
  };
}
