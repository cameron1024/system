{ lib, pkgs, config, username, ... }:

let
  wallpapers = map (pkgs.fetchurl) config.wallpapers;
  wallpaperList = lib.concatStrings (map toString (lib.strings.intersperse " " wallpapers));
  randomWallpaper = pkgs.writeShellScriptBin "random-wallpaper" ''
    cams-home-utilities random-wallpaper ${wallpaperList}
  '';
in

{

  # GTK needs dconf
  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    dracula-icon-theme
    randomWallpaper
  ];

  home-manager.users.${username} = {
    gtk = {
      enable = true;

      theme = {
        name = "Catppuccin-Mocha-Compact-Pink-Dark";
        package = pkgs.catppuccin-gtk.override {
          accents = [ "pink" ];
          size = "compact";
          tweaks = [ "rimless" ];
          variant = "mocha";
        };
      };

      cursorTheme = {
        name = "Catppuccin-Mocha-Lavender-Cursors";
        package = pkgs.catppuccin-cursors.mochaLavender;
      };
    };


    home.packages = with pkgs; [
      swww 
      brightnessctl
    ];

    wayland.windowManager.hyprland.settings = {

      misc = {
        disable_hyprland_logo = true;
      };
  
      exec-once = [
        "swww init && sleep 2 && random-wallpaper"
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
