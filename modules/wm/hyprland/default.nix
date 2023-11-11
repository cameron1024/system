{ pkgs, username, ... }:

{
  imports = [
    ./lock
    ./bar
    ./theme
    ./launcher
    ./notifications
    ./windowing
    # ./displays
  ];

  config = {
    programs.hyprland.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk 
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



        };
      };
    };

  };
}
