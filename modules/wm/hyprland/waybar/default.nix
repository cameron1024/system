{ pkgs, username, displays, ... }:

{
  environment.systemPackages = with pkgs; [
    pavucontrol
  ];

  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings = {
      exec-once = [ "waybar" ];
      bind = [
        "SUPER, b, exec, killall -SIGUSR1 waybar"
      ];
    };
  
    programs.waybar = {
      enable = true;
      style = ./style.css;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          output = map (d: d.name) displays;
          modules-left = [ 
            "hyprland/workspaces" 
            "wlr/taskbar" 
          ];
          modules-center = [ 
            "clock" 
          ];
          modules-right = [ 
            "tray"
            "pulseaudio"
            "temperature" 
            "custom/power_profile" 
            "battery" 
            "backlight" 
            "cpu"
          ];
        };

        "hyprland/workspaces" = {
          format = "{icon}";
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
          on-click = "activate";
        };

        "custom/launch_wofi" = {

        };

        "pulseaudio" = {
          on-click = "pavucontrol";
        };

        "custom/lock_screen" = {
          format = "🔒";
          on-click = "sh -c swaylock & disown";
          tooltip = false;
        };

        "cpu" = {
          interval = 10;
          format = " {usage}%";
          max-length = 10;
          on-click = "kitty --start-as=fullscreen --title btm sh -c 'btm'";
        };

      };
    };
  };
}
