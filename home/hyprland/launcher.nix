{
  machine,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf machine.linux {
    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER, space, exec, rofi -show drun"
      ];
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
