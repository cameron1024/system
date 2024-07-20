{machine, ...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      "SUPER, space, exec, wofi --show drun"
    ];
  };

  programs.wofi = {
    enable = true;
    style = with machine.colorscheme; ''
      
    '';
  };
}
