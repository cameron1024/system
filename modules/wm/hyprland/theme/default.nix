{ pkgs, config, username, ... }:

let
  wallpaper = config.wallpaper;
in

{
  home-manager.users.${username} = {
    home.packages = with pkgs; [
      swww 
      brightnessctl
    ];

    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = ${wallpaper}
      wallpaper = ,${wallpaper}
    '';

    wayland.windowManager.hyprland.settings = {
  
      exec-once = [
        "swww init && swww img ${wallpaper} --transition-step 1 --transition-fps 60 --transition-type random"
      ];

      general = {
        gaps_in = 10;
        gaps_out = 20;
        border_size = 2;
        "col.inactive_border" = "rgb(1e1e2e)";
        "col.active_border" = "rgb(f5c2e7)";
      };

      decoration = {
        rounding = 20;
      };

      animations = {
        enabled = true;
        animation = [
          "windows, 1, 1.5, default"
          "windowsOut, 1, 1.5, default, popin 80%"
          "border, 1, 1.5, default"
          "borderangle, 1, 1.5, default"
          "borderangle, 1, 1.5, default"
          "fade, 1, 1.5, default"
          "workspaces, 1, 1.5, default"
        ];
      };
    };
  };
}
