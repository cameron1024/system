{ pkgs, config, username, ... }:

let
  wallpaper = config.wallpaper;
in

{

  # GTK needs dconf
  programs.dconf.enable = true;

  home-manager.users.${username} = {
    gtk = {
      enable = true;

      font = {
        name = "Fira Sans";
      };

      cursorTheme = {
        name = "Catppuccin-Mocha-Lavender-Cursors";
        package = pkgs.catppuccin-cursors.mochaLavender;
      };

      theme = {
        name = "Catppuccin-Mocha-Compact-Pink-Dark"; 
        package = pkgs.catppuccin-gtk.override {
          accents = [ "pink" ];
          size = "standard";
          tweaks = [];
          variant = "mocha";
        };
      };
    };


    home.packages = with pkgs; [
      swww 
        brightnessctl
    ];

    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = ${wallpaper}
      wallpaper = ,${wallpaper}
    '';

    wayland.windowManager.hyprland.settings = {

      misc = {
        disable_hyprland_logo = true;
      };
  
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
