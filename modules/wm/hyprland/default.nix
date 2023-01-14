{ pkgs, lib, config, ...}:

{
  programs.hyprland.enable = true;

  home-manager.users.cameron = {
    xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
  }
}
