{
  pkgs,
  machine,
  lib,
  ...
}: let
  themeFile =
    pkgs.writeText "style.css"
    # css
    ''
      window#osd {
        padding: 12px 20px;
        border-radius: 999px;
        border: none;
        /* Use Everforest Dark Medium background with 80% opacity */
        background: rgba(45, 53, 59, 0.8); /* #2d353b with 0.8 opacity */

        #container {
          margin: 16px;
        }

        image,
        label {
          /* Use Everforest Dark Medium foreground */
          color: #d3c6aa;
        }

        progressbar:disabled,
        image:disabled {
          opacity: 0.5;
        }

        progressbar {
          min-height: 6px;
          border-radius: 999px;
          background: transparent;
          border: none;
        }

        trough {
          min-height: inherit;
          border-radius: inherit;
          border: none;
          /* Use Everforest Dark Medium foreground with 50% opacity for the trough */
          background: rgba(211, 198, 170, 1); /* #d3c6aa with 0.5 opacity */
        }

        progress {
          min-height: inherit;
          border-radius: inherit;
          border: none;
          /* Use Everforest Dark Medium's green accent for the progress bar */
          background: #a7c080;
        }
      }
    '';
in {
  config = lib.mkIf machine.linux {
    services.swayosd.enable = true;
    services.swayosd.stylePath = "${themeFile}";

    home.packages = [pkgs.brightnessctl pkgs.pulseaudio];

    wayland.windowManager.hyprland.settings = {
      exec-once = [
        "blueman-applet"
        "swayosd-server"
      ];

      bind = [
        ",XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
        ",XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
        ",XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
        ",XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
        ",XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
      ];
    };
  };
}
