{machine, ...}: {
  
  wayland.windowManager.hyprland.settings = {
    bind = [
      "SUPER, space, exec, wofi --show drun"
    ];
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

  programs.rofi = {
    enable = machine.linux;
    cycle = true;
    font = "Fira Code NerdFont";
    
  };
}
