{
  pkgs,
  machine,
  ...
}: let
  colors = with machine.colorscheme; ''
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
in {
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "waybar"
    ];

    bind = [
      "SUPER, b, exec, ${pkgs.killall}/bin/killall -SIGUSR1 .waybar-wrapped"
    ];
  };

  services.blueman-applet.enable = true;

  programs.waybar = {
    enable = true;
    style = colors + (builtins.readFile ./style.css);

    settings = {
      topBar = {
        layer = "top";
        position = "top";
        height = 30;
        output = map (d: d.name) machine.displays;

        modules-left = ["custom/powermenu" "cpu" "memory" "disk" "network"];
        modules-center = ["hyprland/workspaces"];
        modules-right = ["tray" "custom/weather" "backlight" "pulseaudio" "battery" "clock"];

        "cpu" = {
          format = " {usage}%";
        };

        "memory" = {
          format = " {}%";
        };

        "disk" = {
          format = " {free}";
          format-alt = " {percentage_used}% ({free})";
          tooltip = true;
        };

        "network" = {
          format = "󰹹{bandwidthTotalBytes}";
          format-disconnected = "󰖪 ";
          format-alt = " {bandwidthUpBytes} |  {bandwidthDownBytes}";
          format-wifi = "󰖩 {essid}({signalStrength}%)";
          tooltip-format-wifi = "󰖩 {essid}({signalStrength}%)";
          tooltip-format-ethernet = "🌐 {ipaddr}/{cidr}";
          tooltip-format-disconnected = "󰖪 ";
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
          on-click = "pavucontrol";
          on-click-right = "pactl set-sink-mute 0 toggle";
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
        };
      };
    };
  };
}
