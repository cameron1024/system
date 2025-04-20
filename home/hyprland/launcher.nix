{
  machine,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.sherlock.homeManagerModules.default
  ];
  config = lib.mkIf machine.linux {
    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER, space, exec, sherlock"
      ];
    };

    xdg.configFile."sherlock/main.css".text =
      /*
      css
      */
      ''
        * {
          font-family: "FiraCode Nerd Font";
        }
      '';

    programs.sherlock = {
      enable = true;
      settings = {
        aliases = {
          vesktop = {
            name = "Discord";
          };
        };
        config = {
          debug = {
            # try_suppress_warnings = true;
          };
        };
        launchers = [
          {
            name = "App Launcher";
            type = "app_launcher";
            args = {};
            priority = 1;
            home = true;
          }
          {
            name = "Web Search";
            display_name = "Google Search";
            tag_start = "{keyword}";
            tag_end = "{keyword}";
            alias = "gg";
            type = "web_launcher";
            args = {
              "search_engine" = "google";
              "icon" = "google";
            };
            priority = 20;
          }
          {
            name = "docs.rs";
            display_name = "docs.rs";
            tag_start = "{keyword}";
            tag_end = "{keyword}";
            alias = "rs";
            type = "web_launcher";
            args = {
              "search_engine" = "https://docs.rs/{keyword}";
              "icon" = "rust";
            };
            priority = 10;
          }
        ];
      };
    };

    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      cycle = true;
      location = "center";
      terminal = "kitty";
      theme = ./rofi/style.rasi;
    };

    programs.wofi = {
      enable = machine.linux;
      settings = {
        width = 500;
        height = 400;
        term = "kitty";
        normal_window = true;
      };
      style = with machine.colorscheme; ''
        window {
          margin: 0px;
          border: 2px solid ${base0D};
          background-color: ${base00};
          font-size: 18px;
        }

        #input {
          margin: 5px;
          border: none;
          color: ${base04};
          background-color: ${base00};
        }

        #inner-box {
          margin: 5px;
          border: none;
          background-color: ${base00};
        }

        #outer-box {
          margin: 5px;
          border: none;
          background-color: ${base00};
        }

        #scroll {
          margin: 0px;
          border: none;
        }

        #text {
          margin: 5px;
          border: none;
          color: ${base05};
        }

        #entry:selected {
          background-color: ${base02};
        }
      '';
    };
  };
}
