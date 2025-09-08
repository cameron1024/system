{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}: let
  colors = with (import ../../../nixos/machines/colors.nix).everforest; ''
    @define-color bg ${base00};
    @define-color fg ${base04};
    @define-color green ${base0D};
    @define-color greenish ${base0A};
    @define-color blue ${base08};
    @define-color orange ${base0C};
    @define-color red ${base0E};
    @define-color pink ${base0F};
    @define-color yellow ${base0B};
  '';
in
  with lib; {
    options.programs'.waybar = {
      enable = mkEnableOption "waybar";
      enableHyprlandIntegration = mkEnableOption "Hyprland workspace switcher";
    };

    config = mkIf (pkgs.stdenv.isLinux && config.programs'.waybar.enable) {
      wayland.windowManager.hyprland.settings = {
        exec-once = [
          "waybar"
        ];

        bind = [
          "SUPER, b, exec, ${pkgs.killall}/bin/killall -SIGUSR1 .waybar-wrapped"
        ];
      };

      services.blueman-applet.enable = true;

      programs.waybar = lib.mkIf (osConfig != null) {
        enable = true;
        style = colors + (builtins.readFile ./style.css);

        settings = {
          topBar = {
            layer = "top";
            position = "top";
            height = 43;
            output = map (d: d.name) osConfig.services'.desktop.displays or [];
            start_hidden = true;

            modules-left = ["custom/powermenu" "cpu" "memory" "disk" "network"];
            modules-right = ["tray" "custom/weather" "backlight" "pulseaudio" "battery" "clock"];
            modules-center =
              optionals
              config.programs'.waybar.enableHyprlandIntegration
              ["hyprland/workspaces"];

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
              format = "󰃠 {percent:3}%";
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

            "tray" = {
              icon-size = 18;
              spacing = 10;
            };

            "battery" = {
              format = "{icon} {capacity}%";
              format-charging = " {capacity}%";
              format-icons = ["" "" "" "" ""];
              format-plugged = " {capacity}% ";
              states = {
                warning = 20;
                critical = 10;
              };
              interval = 5;
            };

            "custom/powermenu" = {
              format = "󱄅";
              on-click-right = "randomWallpaper.sh";
            };
          };
        };
      };
    };
  }
