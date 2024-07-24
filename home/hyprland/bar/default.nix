{pkgs, machine, ...}: let
  colors = with machine.colorscheme; ''
    @define-color bg ${base00};
    @define-color fg ${base04};
  '';
in {
  wayland.windowManager.hyprland.settings = {
    bind = [
      "SUPER, b, exec, ${pkgs.killall}/bin/killall -SIGUSR1 .waybar-wrapped"
    ];
  };
  
  programs.waybar = {
    enable = true;
    style = colors + (builtins.readFile ./style.css);

    settings = {
      topBar = {
        layer = "top";
        position = "top";
        height = 30;
        output = map (d: d.name) machine.displays;

        modules-left = ["cpu" "memory" "disk" "network"];
        modules-center = ["clock"];
        modules-right = ["tray"];
      };
    };
  };
}
