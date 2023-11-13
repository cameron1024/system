{ pkgs, username, ... }:

let
  wallpaperPath = "/home/${username}/system/assets/background.jpg";
in

{

  home-manager.users.${username} = {

    home.packages = with pkgs; [
      hyprpaper 
      brightnessctl
    ];

    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = ${wallpaperPath}
      wallpaper = eDP-1,${wallpaperPath}
    '';

    wayland.windowManager.hyprland.settings = {
  
      exec-once = [
        "hyprpaper"
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
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

        animation = [
          "windows, 1, 1.5, myBezier"
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
