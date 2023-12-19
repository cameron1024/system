{ pkgs, username, ... }:

let
  change-brightness = delta: pkgs.writeShellScriptBin "change-brightness" ''
    brightnessctl set ${delta}
    MAX_BRIGHTNESS=$(brightnessctl max)
    NEW_BRIGHTNESS=$(brightnessctl get)
    NEW_BRIGHTNESS_PERCENT=$((100 * $NEW_BRIGHTNESS / $MAX_BRIGHTNESS))
    notify-send --category change-brightness $NEW_BRIGHTNESS_PERCENT
  '';

  wallpaperUrl = "https://wallpaperchill.com/download.php?file=https://media.wallpaperchill.com/2880x2560-wallpapers/2880x2560-background-hd-wallpaper-s060.jpg";
  wallpaper = pkgs.fetchurl {
    url = wallpaperUrl;
    hash = "sha256-1J7pW0zTlfT2nGtxF6VW0rO+E+ZqWqbL9zr7wEPb22Y=";
  };
in

{
  imports = [
    ./lock
    ./theme
    ./launcher
    ./notifications
    ./widgets
    ./windowing
    ./displays
  ];

  config = {
    inherit wallpaper;

    programs.hyprland.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk 
        xdg-desktop-portal-wlr
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
      brightnessctl

      powertop

      imv

      (change-brightness "10%+")
    ];

    home-manager.users.${username} = {


      wayland.windowManager.hyprland = {
        enable = true;
        settings = {
          monitor = [
            "eDP-1,1920x1200@60,0x0,1"
          ];

          input = {
            kb_layout = "gb";
            kb_options = "ctrl:nocaps";  # caps lock becomes a second ctrl

            touchpad = {
              natural_scroll = true;
            };
          };

          bind = [
            ",XF86MonBrightnessDown, exec, ${change-brightness "10%-"}/bin/change-brightness"
            ",XF86MonBrightnessUp, exec, ${change-brightness "10%+"}/bin/change-brightness"
          ];

        };
      };
    };

  };
}
