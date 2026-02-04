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

      home.packages = [githubNotifications];

      programs.waybar = lib.mkIf (osConfig != null) {
        enable = true;
        style = ./style2.css;

        settings = {
          topBar = {
            layer = "top";
            position = "top";
            height = 45;
            output = map (d: d.name) osConfig.services'.desktop.displays or [];
            start_hidden = false;

            modules-left = ["cpu" "memory" "disk" "network" "privacy"];
            modules-right = ["tray" "custom/github" "custom/weather" "backlight" "pulseaudio" "battery" "clock"];
            modules-center =
              []
              ++ (optional cfg.enableHyprlandIntegration "hyprland/workspaces")
              ++ (optional cfg.enableNiriIntegration "niri/workspaces");

            "niri/workspaces" = {
              format = "●";
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

