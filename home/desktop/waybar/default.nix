{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}: let
  cfg = config.programs'.waybar;
  githubNotifications = pkgs.writeShellApplication {
    name = "github-notifications.sh";
    runtimeInputs = with pkgs; [ gh jq ];
    text = "gh api notifications | jq length";
  };
  toggleScreenReader = pkgs.writeShellApplication {
    name = "toggle-screen-reader";
    runtimeInputs = with pkgs; [ systemdMinimal jq ];
    text = ''
      current=$(busctl --user --json=short get-property org.a11y.Bus /org/a11y/bus org.a11y.Status ScreenReaderEnabled | jq '.data')
      if [ "$current" = "true" ]; then
        busctl --user set-property org.a11y.Bus /org/a11y/bus org.a11y.Status ScreenReaderEnabled b false
        echo '{"text": "󰈈", "tooltip": "Screen reader: off", "class": "off"}'
      else
        busctl --user set-property org.a11y.Bus /org/a11y/bus org.a11y.Status ScreenReaderEnabled b true
        echo '{"text": "󰈈", "tooltip": "Screen reader: on", "class": "on"}'
      fi
    '';
  };
  screenReaderStatus = pkgs.writeShellApplication {
    name = "screen-reader-status";
    runtimeInputs = with pkgs; [ systemdMinimal jq ];
    text = ''
      current=$(busctl --user --json=short get-property org.a11y.Bus /org/a11y/bus org.a11y.Status ScreenReaderEnabled | jq '.data')
      if [ "$current" = "true" ]; then
        echo '{"text": "󰈈", "tooltip": "Screen reader: on", "class": "on"}'
      else
        echo '{"text": "󰈈", "tooltip": "Screen reader: off", "class": "off"}'
      fi
    '';
  };
in
  with lib; {
    options.programs'.waybar = {
      enable = mkEnableOption "waybar";
      enableHyprlandIntegration = mkEnableOption "Hyprland workspace switcher";
      enableNiriIntegration = mkEnableOption "Niri workspace switcher";
    };

    config = mkIf (pkgs.stdenv.isLinux && cfg.enable) {
      wayland.windowManager.hyprland.settings = {
        exec-once = [
          "waybar"
        ];

        bind = [
          "SUPER, b, exec, ${pkgs.killall}/bin/killall -SIGUSR1 .waybar-wrapped"
        ];
      };

      services.blueman-applet.enable = true;

      home.packages = [githubNotifications toggleScreenReader screenReaderStatus];

      programs.waybar = lib.mkIf (osConfig != null) {
        enable = true;
        style = ./style.css;

        settings = {
          topBar = {
            layer = "top";
            position = "top";
            height = 45;
            output = map (d: d.name) (filter (d: !d.auxiliary) (osConfig.services'.desktop.displays or []));
            start_hidden = true;
            smooth-scrolling-threshold = 5;

            modules-left = ["power-profiles-daemon" "cpu" "memory" "disk" "network" "privacy"];
            modules-right = ["custom/a11y" "tray" "custom/github" "custom/weather" "backlight" "pulseaudio" "battery" "clock"];
            modules-center =
              []
              ++ (optional cfg.enableHyprlandIntegration "hyprland/workspaces")
              ++ (optional cfg.enableNiriIntegration "niri/workspaces");

            "niri/workspaces" = {
              format = "●";
            };

            "power-profiles-daemon" = let
              icon = cp: builtins.fromJSON ''"\u${cp}"'';
            in {
              format = "{icon} ";
              tooltip-format = "Power profile: {profile}\nDriver: {driver}";
              tooltip = true;
              format-icons = {
                default = icon "F0E7";      # nf-fa-bolt
                performance = icon "F135";  # nf-fa-rocket
                balanced = icon "F24E";     # nf-fa-balance_scale
                power-saver = icon "F06C";  # nf-fa-leaf
              };
            };

            "cpu" = {
              format = "  {usage}%";
            };

            "memory" = {
              format = "  {}%";
            };

            "disk" = {
              format = "  {free}";
              format-alt = "  {percentage_used}% ({free})";
              tooltip = true;
            };

            "network" = {
              format = "󰹹 {bandwidthTotalBytes}";
              format-disconnected = "󰖪 ";
              format-alt = " {bandwidthUpBytes} |  {bandwidthDownBytes}";
              format-wifi = "󰖩  {essid}({signalStrength}%)";
              tooltip-format-wifi = "󰖩  {essid}({signalStrength}%)";
              tooltip-format-ethernet = "🌐  {ipaddr}/{cidr}";
              tooltip-format-disconnected = "󰖪  ";
              on-click-right = "nm-connection-editor";
            };

            "custom/weather" = {
              format = "{}°";
              tooltip = true;
              interval = 3600;
              exec = "${pkgs.wttrbar}/bin/wttrbar --location London";
              return-type = "json";
            };

            "backlight" = {
              format = "󰃠  {percent:3}%";
              on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl set 5%+";
                            on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
              on-click = "${pkgs.brightnessctl}/bin/brightnessctl set $(hypr-utils store cycle brightness 20 50 70 100)%";
            };

            "pulseaudio" = {
              format = "{icon} {volume:3}";
              format-bluetooth = "{icon}  {volume:3}%";
              format-bluetooth-muted = "󰝟 {icon}";
              format-muted = "󰝟 {volume:3}";
              tooltip-format = "{icon} {desc} // {volume}%";
              scroll-step = 5;
              format-icons = {
                headphone = "";
                hands-free = "";
                headset = "";
                phone = "";
                portable = "";
                car = "";
                default = ["" "" ""];
              };
              on-click-right = "pavucontrol";
              on-click = "pactl set-sink-mute 0 toggle";
            };

            "custom/a11y" = {
              format = "{}";
              return-type = "json";
              interval = 5;
              exec = "${screenReaderStatus}/bin/screen-reader-status";
              on-click = "${toggleScreenReader}/bin/toggle-screen-reader";
            };

            "tray" = {
              icon-size = 18;
              spacing = 10;
            };

            "battery" = {
              format = "{icon}  {capacity}%";
              format-charging = "  {capacity}%";
              format-icons = ["" "" "" "" ""];
              format-plugged = "  {capacity}% ";
              states = {
                warning = 20;
                critical = 10;
              };
              interval = 5;
            };

            "custom/powermenu" = {
              format = "󱄅";
              on-click-right = "set-wallpaper.sh";
            };

            "custom/github" = {
              format = "<span font='FiraCode Nerd Font'></span> {}";
              markup = true;
              interval = 300;
              exec = "${githubNotifications}/bin/github-notifications.sh";
              on-click = "xdg-open https://github.com/notifications";
            };
          };
        };
      };
    };
  }

