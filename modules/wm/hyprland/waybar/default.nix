{
  pkgs,
  username,
  displays,
  laptop,
  ...
}: let
  # save battery if we're on a laptop
  defaultInterval = 0.5;
  launchBtm = "wezterm start btm";

  transition = "all 0.2s ease-in-out";

  left-border = "24px 10px 24px 10px";
  right-border = "10px 24px 10px 24px";

  base = "#1e1e2e";
  mantle = "#181825";
  crust = "#11111b";

  text = "#cdd6f4";
  subtext0 = "#a6adc8";
  subtext1 = "#bac2de";

  surface0 = "#313244";
  surface1 = "#45475a";
  surface2 = "#585b70";

  overlay0 = "#6c7086";
  overlay1 = "#7f849c";
  overlay2 = "#9399b2";

  blue = "#89b4fa";
  lavender = "#b4befe";
  sapphire = "#74c7ec";
  sky = "#89dceb";
  teal = "#94e2d5";
  green = "#a6e3a1";
  yellow = "#f9e2af";
  peach = "#fab387";
  maroon = "#eba0ac";
  red = "#f38ba8";
  mauve = "#cba6f7";
  pink = "#f5c2e7";
  flamingo = "#f2cdcd";
  rosewater = "#f5e0dc";

  cava = {
    autosens = 1;
    bar_delimiter = 0;
    bars = 18;
    format-icons = [
      "<span foreground='${mauve}'>▁</span>"
      "<span foreground='${mauve}'>▂</span>"
      "<span foreground='${mauve}'>▃</span>"
      "<span foreground='${mauve}'>▄</span>"
      "<span foreground='${blue}'>▅</span>"
      "<span foreground='${blue}'>▆</span>"
      "<span foreground='${blue}'>▇</span>"
      "<span foreground='${blue}'>█</span>"
    ];
    framerate = 120;
    higher_cutoff_freq = 10000;
    lower_cutoff_freq = 50;
    # input_delay = 2;
    method = "pipewire";
    monstercat = false;
    reverse = false;
    source = "auto";
    stereo = true;
    waves = false;
  };
in {
  environment.systemPackages = with pkgs; [
    pavucontrol
  ];

  services.upower = {
    enable = true;
  };

  services.cpupower-gui.enable = true;

  home-manager.users.${username} = {
    services.playerctld.enable = true;
    programs.cava.enable = true;

    home.packages = with pkgs; [
      playerctl
    ];

    wayland.windowManager.hyprland.settings = {
      exec-once = ["waybar"];

      bind = [
        "SUPER, b, exec, killall -SIGUSR1 .waybar-wrapped"
      ];
    };

    programs.waybar = {
      enable = true;
      style = ''
        * {
          border: none;
          border-radius: 0px;
          font-size: 16px;
          font-family: FiraCode Nerd Font;
          min-height: 0;
        }

        window#waybar {
          background-color: ${crust};
          border-radius: 0px;
          color: ${text};
        }

        #cava.left {
          border-radius: ${left-border};
        }

        #cava.right {
          border-radius: ${right-border};
        }

        #workspaces {
          background: ${base};
          margin: 5px 5px;
          padding: 8px 8px;
          border-radius: 16px;
          color: ${blue};
        }

        #workspaces button {
          padding: 0px 5px;
          margin: 0px 3px;
          border-radius: 16px;
          color: ${blue};
          background: ${crust};
          transition: ${transition};
        }

        #workspaces button.active {
          color: ${base};
          background-color: ${blue};
          background-size: 400% 400%;
          border-radius: 16px;
          transition: ${transition};
          min-width: 50px;
        }

        #workspaces button:hover {
          background-color: #f5f5f5;
          color: #11111B;
          border-radius: 16px;
          min-width: 50px;
          background-size: 400% 400%;
        }

        #tray, #pulseaudio, #network, #battery, #cpu, #memory, #disk, #custom-playerctl.backward #custom-playerctl.play #custom-playerctl.forward {
          background: ${base};
          font-weight: bold;
          margin: 5px 0px;
        }

        #tray, #pulseaudio, #network, #battery, #cpu, #memory, #disk {
          border-radius: ${right-border};
          padding: 0 20px;
          margin-left: 7px;
        }

        #clock {
          color: ${green}
        }

        #cpu {
          color: ${yellow}
        }

        #memory {
          color: ${pink}
        }

        #network {
          color: ${sky}
        }

        #battery {
          color: ${sapphire}
        }

        #disk {
          color: ${teal}
        }

        #clock {
          color: ${flamingo};
          background: ${base};
          border-radius: 0px 0px 0px 40px;
          padding: 10px 10px 15px 25px;
          font-weight: bold;
        }

        #custom-launcher {
          color: ${mauve};
          background: ${base};
          border-radius: 0px 0px 40px 0px;
          padding: 0px 15px 0px 15px;
        }

        #custom-playerctl.backward, #custom-playerctl.play, #custom-playerctl.forward {
            font-size: 22px;
        }

        #custom-playerctl.backward:hover, #custom-playerctl.play:hover, #custom-playerctl.forward:hover{
            color: ${text};
        }

        #custom-playerctl.backward {
            color: ${rosewater};
            border-radius: 24px 0px 0px 10px;
            padding-left: 16px;
            margin-left: 7px;
        }

        #custom-playerctl.play {
            color: ${red};
            padding: 0 5px;
        }

        #custom-playerctl.forward {
            color: ${rosewater};
            border-radius: 0px 10px 24px 0px;
            padding-right: 12px;
            margin-right: 7px
        }

        #custom-playerlabel {
            background: ${base};
            color: ${text};
            padding: 0 20px;
            border-radius: ${left-border};
            margin: 5px 0;
            font-weight: bold;
        }

        #window{
            background: ${base};
            padding-left: 15px;
            padding-right: 15px;
            border-radius: 16px;
            margin-top: 5px;
            margin-bottom: 5px;
            font-weight: normal;
            font-style: normal;
        }


      '';

      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 40;
          output = map (d: d.name) displays;
          spacing = 0;
          margin-top = 0;

          modules-left = [
            "custom/launcher"
            "custom/playerctl#backward"
            "custom/playerctl#play"
            "custom/playerctl#forward"
            "custom/playerlabel"
          ];
          modules-center = [
            "cava#left"
            "hyprland/workspaces"
            "cava#right"
          ];
          modules-right = [
            "network"
            "cpu"
            "memory"
            "disk"
            "backlight"
            "pulseaudio"
            "battery"
            "tray"
            "clock"
          ];

          "battery" = {
            format = "{icon} {capacity}%";
            format-alt = "{icon} {time}";
            format-charging = "  {capacity}%";
            format-icons = ["" "" "" "" ""];
            format-plugged = " {capacity}% ";
          };

          "cava#left" = cava;
          "cava#right" = cava;

          "clock" = {
            # format = "{%h:%M}";
            format-alt = " {:%d/%m}";
            tooltip = "true";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };

          "cpu" = {
            interval = defaultInterval;
            format = "󰍛 {usage}%";
            on-click = launchBtm;
          };

          "custom/launcher" = {
            format = " ";
            on-click = "wofi";
            tooltip = false;
          };

          "custom/playerctl#backward" = {
            format = "󰙣 ";
            on-click = "playerctl previous";
            on-scroll-down = "playerctl volume 0.05-";
            on-scroll-up = "playerctl volume 0.05+";
          };

          "custom/playerctl#forward" = {
            format = "󰙡 ";
            on-click = "playerctl next";
            on-scroll-down = "playerctl volume 0.05-";
            on-scroll-up = "playerctl volume 0.05+";
          };

          "custom/playerctl#play" = {
            exec = ''
              playerctl -a metadata --format '{"text": "{{artist}} - {{markup_escape(title)}}", "tooltip": "{{playerName}} : {{markup_escape(title)}}", "alt": "{{status}}", "class": "{{status}}"}' -F
            '';
            format = "{icon}";
            format-icons = {
              Playing = "<span>󰏥 </span>";
              Paused = "<span> </span>";
              Stopped = "<span> </span>";
            };
            on-click = "playerctl play-pause";
            on-scroll-down = "playerctl volume 0.05-";
            on-scroll-up = "playerctl volume 0.05+";
            return-type = "json";
          };

          "custom/playerlabel" = {
            exec = ''
              playerctl -a metadata --format '{"text": "{{artist}} - {{markup_escape(title)}}", "tooltip": "{{playerName}} : {{markup_escape(title)}}", "alt": "{{status}}", "class": "{{status}}"}' -F
            '';
            format = "<span>󰎈 {} 󰎈</span>";
            max-length = 40;
            on-click = "";
            return-type = "json";
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
            format-icons = ["" "" "" "" ""];
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

          "pulseaudio" = {
            format = "{icon} {volume}";
            format-bluetooth = "{icon}  {volume}%";
            format-bluetooth-muted = "󰝟 {icon}";
            format-muted = "󰝟 {volume}";
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
            on-right-click = "pactl set-sink-mute 0 toggle";
          };

          "backlight" = {
            format = "󰃠 {percent}%";
          };

          "tray" = {
            icon-size = 20;
            spacing = 8;
          };
        };
      };
    };
  };
}
