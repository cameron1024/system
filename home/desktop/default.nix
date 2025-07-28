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
    ./quickshell
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
    programs'.quickshell.enable = true;
    programs'.departure.enable = true;

    xdg.userDirs.enable = true;

    home.packages = with pkgs; [
      libnotify
      wl-clipboard
      google-chrome
    ];
  };
}
