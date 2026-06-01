{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}: let
  cfg = config.programs'.waybar;
  fcitxStatus = pkgs.writeShellApplication {
    name = "fcitx-status.sh";
    runtimeInputs = with pkgs; [ fcitx5 ];
    text = ''
      status=$(fcitx5-remote -n 2>/dev/null || echo "keyboard-us")
      case "$status" in
        "mozc") echo '{"text": "あ", "tooltip": "Mozc (Japanese)", "class": "mozc"}' ;;
        "pinyin"|"shuangpin") echo '{"text": "拼", "tooltip": "Pinyin (Chinese)", "class": "pinyin"}' ;;
        "keyboard-us") echo '{"text": "En", "tooltip": "English (US)", "class": "english"}' ;;
        *) echo "{\"text\": \"$status\", \"tooltip\": \"$status\", \"class\": \"other\"}" ;;
      esac
    '';
  };
  fcitxCycle = pkgs.writeShellApplication {
    name = "fcitx-cycle.sh";
    runtimeInputs = with pkgs; [ fcitx5 ];
    text = ''
      current=$(fcitx5-remote -n 2>/dev/null || echo "keyboard-us")
      # Get all available input methods from fcitx5
      all=$(fcitx5-remote -l 2>/dev/null || echo "keyboard-us")
      # Build ordered list
      ims=$(echo "$all" | tr ' ' '\n' | grep -v '^$')
      count=$(echo "$ims" | wc -l)
      if [ "$count" -le 1 ]; then
        exit 0
      fi
      # Find the index of the current IM and switch to the next one
      i=0
      next=""
      found=0
      while IFS= read -r im; do
        i=$((i + 1))
        if [ "$found" -eq 1 ]; then
          next="$im"
          found=2
          break
        fi
        if [ "$im" = "$current" ]; then
          found=1
        fi
      done <<< "$ims"
      # If current was last (or not found), wrap to first
      if [ -z "$next" ]; then
        next=$(echo "$ims" | head -n 1)
      fi
      fcitx5-remote -s "$next"
    '';
  };
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

      home.packages = [githubNotifications fcitxStatus fcitxCycle];

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
            modules-right = ["tray" "custom/github" "custom/weather" "custom/fcitx" "backlight" "pulseaudio" "battery" "clock"];
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

            "custom/fcitx" = {
              format = "{}";
              return-type = "json";
              interval = 2;
              exec = "${fcitxStatus}/bin/fcitx-status.sh";
              on-click = "${fcitxCycle}/bin/fcitx-cycle.sh";
              tooltip = true;
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

