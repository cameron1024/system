{
  lib,
  pkgs,
  username,
  inputs,
  ...
}: let
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

    {
      url = "https://github.com/Gingeh/wallpapers/blob/main/landscapes/evening-sky.png";
      hash = "sha256-YwPVgcm6calF6gORx8L0FQTSIWdDlvNUApFQ9w5uGh4=";
    }
  ];
in {
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
    ./screenshot
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
      sutils # battery, etc

      libnotify
      glib

      powertop

      pcmanfm
      imv

      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
      hyprpicker

      nwg-look

      iwgtk

      modem-manager-gui
    ];

    networking.wireless.iwd.enable = true;

    home-manager.users.${username} = {
      wayland.windowManager.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.system}.default;
        settings = {
          exec-once = [
            "pcmanfm --daemon-mode"
          ];


        };

      };
    };
  };
}
