{ pkgs, ... }:

{
  home-manager.users.cameron = {
    programs.eww = {
      enable = true;
      package = pkgs.eww-wayland;
      configDir = ./config;
    };
  };
}
