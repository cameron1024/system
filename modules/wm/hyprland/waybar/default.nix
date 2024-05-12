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

  transition = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";

  base = "1e1e2e";
  mantle = "181825";
  crust = "11111b";

  text = "cdd6f4";
  subtext0 = "a6adc8";
  subtext1 = "bac2de";

  surface0 = "313244";
  surface1 = "45475a";
  surface2 = "585b70";

  overlay0 = "6c7086";
  overlay1 = "7f849c";
  overlay2 = "9399b2";

  blue = "89b4fa";
  lavender = "b4befe";
  sapphire = "74c7ec";
  sky = "89dceb";
  teal = "94e2d5";
  green = "a6e3a1";
  yellow = "f9e2af";
  peach = "fab387";
  maroon = "eba0ac";
  red = "f38ba8";
  mauve = "cba6f7";
  pink = "f5c2e7";
  flamingo = "f2cdcd";
  rosewater = "f5e0dc";
in {
  environment.systemPackages = with pkgs; [
    pavucontrol
  ];

  services.upower = {
    enable = true;
  };

  services.cpupower-gui.enable = true;

  home-manager.users.${username} = {
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
            font-size: 16px;
            font-family: FiraCode Nerd Font, Font Awesome, sans-serif;
            font-weight: bold;
          }

          window#waybar {
            background-color: #${base};
            border-radius: 0px;
            color: #${text};
          }

          #workspaces {
            background: #${mantle};
            margin: 2px;
            padding: 0px 1px;
            border-radius: 15px;
            border: 0px;
            font-style: normal;
            color: #${base};
          }

          #workspaces button {
            padding: 0px 5px;
            margin: 4px 3px;
            border-radius: 10px;
            border: 0px;
            color: #${base};
            background: linear-gradient(45deg, #${mauve}, #${flamingo}, #${blue}, #${peach});
            background-size: 300% 300%;
            animation: gradient_horizontal 15s ease infinite;
            opacity: 0.5;
            transition: ${transition};
          }

          #workspaces button.active {
            padding: 0px 5px;
            margin: 4px 3px;
            border-radius: 10px;
            border: 0px;
            color: #${base};
            background: linear-gradient(45deg, #${mauve}, #${flamingo}, #${blue}, #${peach});
            background-size: 300% 300%;
            animation: gradient_horizontal 15s ease infinite;
            transition: ${transition};
            opacity: 1.0;
            min-width: 40px;
        }



        #workspaces button:hover {
            border-radius: 10px;
            color: #${base};
            background: linear-gradient(45deg, #${mauve}, #${flamingo}, #${blue}, #${peach});
            background-size: 300% 300%;
            animation: gradient_horizontal 15s ease infinite;
            opacity: 0.8;
            transition: ${transition};
        }

        @keyframes gradient_horizontal {
          0% {
            background-position: 0% 50%;
          }
          50% {
            background-position: 100% 50%;
          }
          100% {
            background-position: 0% 50%;
          }
              }
              @keyframes swiping {
                0% {
            background-position: 0% 200%;
          }
          100% {
            background-position: 200% 200%;
          }
        }

        tooltip {
          background: #${base};
          border: 1px solid #${mauve};
          border-radius: 10px;
        }

        tooltip label {
          color: #${lavender};
        }

        #window {
          margin: 4px;
          padding: 2px 10px;
          color: #${text};
          background: #${mantle};
          border-radius: 10px;
        }

        #memory {
          color: #${flamingo};
          background: ${mantle};
          margin: 4px;
          padding: 2px 10px;
          border-radius: 10px;
        }

        #clock {
          color: #${mantle};
          background: linear-gradient(45deg, #${teal}, #${flamingo}, #${green}, #${peach});
          background-size: 300% 300£;
          animation: gradient_horizontal 15s ease infinite;
          margin: 4px;
          padding: 2px 10px;
          border-radius: 10px;
        }

        #memory {
          color: #${flamingo};
          background: ${mantle};
          margin: 4px;
          padding: 2px 10px;
          border-radius: 10px;
        }




      '';

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

          modules-center = ["hyprland/workspaces"];
          modules-left = ["custom/startmenu" "hyprland/window" "pulseaudio" "cpu" "memory"];
          modules-right = ["custom/hyprbindings" "custom/exit" "idle_inhibitor" "custom/themeselector" "custom/notification" "battery" "clock" "tray"];

          "hyprland/workspaces" = {
            format = "{icon}";
            format-icons = {
              default = " ";
              active = " ";
              urgent = " ";
            };
            on-scroll-up = "hyprctl dispatch workspace e+1";
            on-scroll-down = "hyprctl dispatch workspace e-1";
          };

          "custom/browser" = {
            format = "󰖟";
            on-click = "google-chrome-stable";
          };

          "custom/files" = {
            format = "";
            on-click = "wezterm start yazi";
          };

          "custom/terminal" = {
            format = "";
            on-click = "wezterm";
          };

          "custom/power" = {
            format = "";
            on-click = "wlogout";
          };

          "hyprland/language" = {
            format = "{}";
            format-en = "EN";
            format-zh = "ZH";
            on-click = "hyprctl switchxkblayout thinkpad-extra-buttons next";
          };

          "hyprland/window" = {
            format = "{title}";
          };

          "tray" = {
            spacing = 10;
          };

          "clock" = {
            format = "{:%H:%M}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
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
              default = ["" "" ""];
            };
            on-click = "pavucontrol";
          };

          "backlight" = {
            format = "󰃠 {percent}%";
          };

          "custom/launcher" = {
            format = " ";
            on-click = "pkill rofi || ~/.config/rofi/launcher.sh";
            tooltip = false;
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
        };
      };
    };
  };
}
