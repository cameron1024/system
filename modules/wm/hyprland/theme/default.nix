{ username, ... }:

{

  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings = {

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
          "windows, 1, 2, myBezier"
          "windowsOut, 1, 2, default, popin 80%"
          "border, 1, 2, default"
          "borderangle, 1, 2, default"
          "borderangle, 1, 2, default"
          "fade, 1, 2, default"
          "workspaces, 1, 2, default"
        ];
      };
    };
  };
}
