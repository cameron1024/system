{ pkgs, username, displays, laptop, ... }:
let 
  # save battery if we're on a laptop
  defaultInterval = 0.5;
  launchBtm = "wezterm start btm";
in

{
  environment.systemPackages = with pkgs; [
    pavucontrol
  ];

  services.upower = {
    enable = true;
  };

  services.cpupower-gui.enable = true;

  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings = {
      exec-once = [ "waybar" ];

      bind = [
        "SUPER, b, exec, killall -SIGUSR1 .waybar-wrapped"
      ];
    };

  
    programs.waybar = {
      enable = true;
      style = ./style3.css;
      # systemd.enable = true;

      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 48;
          output = map (d: d.name) displays;
          spacing = 0;
          margin-top = 0;
          margin-left = 10;
          margin-right = 10;
          modules-left = [ 
            "custom/menu"
            "hyprland/workspaces"
            "custom/updates"
          ];
          modules-center = [ 
            "custom/playerctl"
            "custom/playerlabel"
          ];
          modules-right = [
            "network"
            "custom/div"
            "pulseaudio"
            "custom/div"
            "clock"
            "tray"
            "custom/power"
          ];

          "clock" = {
            format = "{:%H:%M}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };

          "custom/wlogout" = {
            format= "󰜗";
            interval = "once";
            on-click = "wlogout";
          };

          "custom/launcher" = {
            format = "{}";
            tooltip = true;
            interval = defaultInterval;
            on-click = "wofi";
          };

          "cpu" = {
            interval = defaultInterval;
            format = "󰍛 {usage}%";
            on-click = launchBtm;
          };

          "memory" = {
            interval = defaultInterval;
            format = " {percentage}%";
            max-length = 30;
            tooltip = true;
            # tooltip-format = " {used:0.1f}GB/{total:0.1f}GB";
            on-click = launchBtm;
          };

          "temperature" = {
            interval = defaultInterval;
            on-click = launchBtm;
            format = "{temperatureC}°C ";
            format-icons = [ "" "" "" "" "" ];
          };

          "disk" = {
            format = " {free}";
            format-alt = " {percentage_used}% ({free})";
            tooltip = true;
            on-click-right = "kitty --start-as=fullscreen --title all_is_kitty sh -c 'ncdu'";
            interval = 10;
          };

          "network" = {
            format = "󰹹{bandwidthTotalBytes}";
            format-disconnected = "No Internet⚡";
            format-linked = "{ifname} (No IP)!!";
            format-alt = " {bandwidthUpBytes} |  {bandwidthDownBytes}";
            format-wifi = "{essid}({signalStrength}%) 󰖩 ";
            format-ethernet = "🌐 {ipaddr}/{cidr} ";
            tooltip-format-wifi = "󰖩  {essid}({signalStrength}%)";
            tooltip-format-ethernet = "🌐 {ipaddr}/{cidr}";
            tooltip-format-disconnected = "󰖪 ";
            on-click-right = "nm-connection-editor";
            interval = defaultInterval;
          };

          "hyprland/workspaces" = {
            disable-scroll = false;
            on-scroll-up = "hyprctl dispatch workspace -1";
            on-scroll-down = "hyprctl dispatch workspace +1";
            format = "{name}";
            format-icons = {
              urgent = "󰗖";
              active = "󰝥";
              default = "󰝦";
            };
          };

          "hyprland/window" = {
            format = "{}";
            separate-outputs = true;
            max-length = 32;
            rewrite = {
              "(.*)tmux" = "";
              "(.*)Google Chrome" = "";
            };
          };

          "pulseaudio" = {
            format = "{icon} {volume}";
            format-bluetooth = "{icon}  {volume}%";
            format-bluetooth-muted = "󰝟 {icon}";
            format-muted = "婢 {volume}";
            tooltip-format = "{icon} {desc} // {volume}%";
            scroll-step = 5;
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [ "" "" "" ];
            };
            on-click = "pavucontrol";
          };

          "backlight" = {
            format = "󰃠 {percent}%";
          };

          "custom/notifications" = {
            format = "{icon}";
            format-icons = {
              notification = " <span foreground='red'><sup></sup></span>";
              none = "";
              dnd-notification = "<span foreground='red'><sup></sup></span>";
              dnd-none = "";
            };
            # return-type = "json";
            # exec-if = "which swaync-client";
            # exec = "swaync-client -swb";
            # on-click = "swaync-client -t -sw";
            # on-click-right = "swaync-client -d -sw";
            # escape = true;
          };

          "tray" = {
            spacing = 10;
          };


        };




      };
    };
  };
}
