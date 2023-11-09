{ pkgs, ... }:

{
  home-manager.users.cameron = {


    wayland.windowManager.hyprland.settings = {
      exec-once = [ "waybar" ];
    };

  
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          output = [ "eDP-1" ];
          modules-left = [ "hyprland/workspaces" "wlr/taskbar" ];
          modules-right = [ "temperature" ];
        };

        "hyprland/workspaces" = {
          format = "{icon}";
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
          on-click = "activate";
        };
      };
    };
  };
}
