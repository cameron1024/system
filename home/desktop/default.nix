{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  imports = [
    ./audio.nix
    ./gtk.nix
    ./lock
    ./power-menu.nix
    ./waybar
    ./rofi
  ];

  options = {
    services'.desktop.enable = mkEnableOption "desktop";
  };

  config = mkIf config.services'.desktop.enable {
    gtk'.enable = true;

    programs'.waybar.enable = true;
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
