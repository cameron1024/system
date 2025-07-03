{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  imports = [
    ./gtk.nix
    ./lock
    ./power-menu.nix
    ./quickshell
    ./waybar
  ];

  options = {
    services'.desktop.enable = mkEnableOption "desktop";
  };

  config = mkIf config.services'.desktop.enable {
    gtk'.enable = true;

    programs'.waybar.enable = true;
    programs'.quickshell.enable = true;
    programs'.departure.enable = true;

    home.packages = with pkgs; [
      libnotify
      wl-clipboard
      google-chrome
    ];
  };
}
