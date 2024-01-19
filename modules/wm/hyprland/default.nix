{ lib, pkgs, username, inputs, ... }:

let
  wallpapers = [
    # {
    #   url = "https://github.com/xerolinux/xero-catppuccin-wallpapers/blob/main/usr/share/wallpapers/Catppuccin%20-%2013.png";
    #   hash = "sha256-kwcw+P8NoJPnGPdAQ8NqHfU1RbwYkkc0e0iYb7vVX2k=";
    # }

    {
      url = "https://w.wallhaven.cc/full/6d/wallhaven-6dygpl.jpg";
      hash = "sha256-GXrhyPoLdl3EncpLNNdVJs1YLyB7Bd2VxyqunbniC0k=";
    }

    {
      url = "https://i.redd.it/n4futnleiuia1.png";
      hash = "sha256-2CMsp3bltiABLTkUEwj9hQ+ovBPXcnkp5POtOd10OfA=";
    }
  ];
in

{
  imports = [
    ./greeter
    ./lock
    ./theme
    ./launcher
    ./notifications
    ./services
    ./windowing
    ./displays
    ./waybar
    ./input
    ./wofi
    ./wlogout
    ./utilities
  ];

  options = with lib; {
    wallpapers = mkOption {};
  };

  config = {
    inherit wallpapers;

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
      ];
      config.common.default = "*";
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

      nwg-look
    ];

    home-manager.users.${username} = {
      wayland.windowManager.hyprland.enable = true;
    };

  };
}
