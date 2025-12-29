{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
with lib; {
  imports = [
    inputs.noctalia.homeModules.default

    ./ai.nix
    ./audio.nix
    ./gtk.nix
    ./lock
    ./noctalia.nix
    ./one-password.nix
    ./power-menu.nix
    ./waybar
    ./walker.nix
    ./rofi
    ./wallpaper.nix
  ];

  options = {
    services'.desktop.enable = mkEnableOption "desktop";
  };

  config = mkIf config.services'.desktop.enable {
    gtk'.enable = true;

    programs'.waybar.enable = true;
    programs'.waybar.enableNiriIntegration = true;
    programs'.rofi.enable = true;
    programs'.departure.enable = true;

    services.darkman.enable = true;

    xdg = {
      enable = true;
      userDirs.enable = true;
      # portal.enable = true;
      # portal.config.common.default = "*";
      # portal.extraPortals = with pkgs; [
      #   xdg-desktop-portal-wlr
      #   xdg-desktop-portal-gtk
      # ];
    };

    home.packages =
      if pkgs.stdenv.isLinux
      then
        (with pkgs; [
          libnotify
          wl-clipboard
          google-chrome
          inputs.hexecute.packages.${pkgs.system}.default
          s-tui
        ])
      else [];
  };

}
