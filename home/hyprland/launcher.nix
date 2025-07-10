{
  pkgs,
  machine,
  lib,
  ...
}: 

let colorscheme = {
    name = "everforest";
    base00 = "#2b3339";
    base01 = "#323c41";
    base02 = "#503946";
    base03 = "#868d80";
    base04 = "#d3c6aa";
    base05 = "#d3c6aa";
    base06 = "#e9e8d2";
    base07 = "#fff9e8";
    base08 = "#7fbbb3";
    base09 = "#d699b6";
    base0A = "#83c092";
    base0B = "#dbbc7f";
    base0C = "#e69875";
    base0D = "#a7c080";
    base0E = "#e67e80";
    base0F = "#d699b6";
  };

in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER, space, exec, rofi -show drun"
      ];
    };

    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      cycle = true;
      font = "Fira Code NerdFont";
      location = "center";
      terminal = "kitty";
      theme = ./rofi/style.rasi;
    };

    programs.wofi = {
      enable = true;
      settings = {
        width = 500;
        height = 400;
        term = "kitty";
        normal_window = true;
      };
      style = with colorscheme; ''
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
