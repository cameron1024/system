{ pkgs, ... }:

{

  imports = [
    ./waybar
  ];

  programs.hyprland.enable = true;
  programs.xwayland.enable = true;

  services.xserver.xkbOptions = "ctrl:nocaps";

  home-manager.users.cameron = {
    xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;

    home.packages = with pkgs; [
      wofi
      xkb-switch

      swayidle
      swaylock
    ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
  };

  security.pam.services.swaylock = {
    text = "auth include login";
  };
}
