{ lib, pkgs, username, inputs, ... }:

let
  wallpaperUrl = "https://i.redd.it/n4futnleiuia1.png";
  wallpaper = pkgs.fetchurl {
    url = wallpaperUrl;
    hash = "sha256-2CMsp3bltiABLTkUEwj9hQ+ovBPXcnkp5POtOd10OfA=";
  };
in

{
  imports = [
    ./greeter
    ./lock
    ./theme
    ./launcher
    ./notifications
    ./widgets
    ./windowing
    ./displays
    ./waybar
    ./keyboard
    ./wofi
    ./wlogout
    ./utilities
  ];

  options = with lib; {
    wallpaper = mkOption {};
  };

  config = {
    inherit wallpaper;

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
      ];
    };

    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    environment.systemPackages = with pkgs; [
      sutils  # battery, etc

      libnotify
      glib

      powertop

      imv

      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
      hyprpicker
    ];

    home-manager.users.${username} = {
      wayland.windowManager.hyprland.enable = true;
    };

  };
}
