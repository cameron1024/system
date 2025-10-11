{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  imports = [
    ./ai.nix
    ./audio.nix
    ./gtk.nix
    ./lock
    ./power-menu.nix
    ./waybar
    ./walker.nix
    ./rofi
    ./quickshell
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

    xdg.userDirs.enable = true;

    home.packages = if pkgs.stdenv.isLinux then (with pkgs; [
      libnotify
      wl-clipboard
      google-chrome
    ]) else[];
  };
}
