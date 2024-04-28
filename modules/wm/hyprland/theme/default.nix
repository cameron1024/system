{
  lib,
  pkgs,
  config,
  username,
  inputs,
  ...
}: let
  cli = inputs.catppuccinifier.packages.${pkgs.system}.cli;

  makeWallpaper = {url}: let
    wallpaperFile = pkgs.fetchurl url;
  in
    pkgs.stdenv.mkDerivation {
      buildInputs = [cli];
      buildPhase = ''
        ${cli}/bin/catppuccinifier-cli --image ${wallpaperFile}
      '';
    };

  wallpapers = map (pkgs.fetchurl) config.wallpapers;
  wallpaperList = lib.concatStrings (map toString (lib.strings.intersperse " " wallpapers));
  randomWallpaper = pkgs.writeShellScriptBin "random-wallpaper" ''
    cams-home-utilities random-wallpaper ${wallpaperList}
  '';
in {
  imports = [
    ./wallpaper.nix
  ];

  config = {
    # GTK needs dconf
    programs.dconf.enable = true;

    environment.systemPackages = with pkgs; [
      dracula-icon-theme
      cli
      randomWallpaper
    ];

    home-manager.users.${username} = {
      gtk = {
        enable = true;

        theme = {
          name = "Catppuccin-Mocha-Compact-Pink-Dark";
          package = pkgs.catppuccin-gtk.override {
            accents = ["pink"];
            size = "compact";
            tweaks = ["rimless"];
            variant = "mocha";
          };
        };

        cursorTheme = {
          name = "Catppuccin-Mocha-Lavender-Cursors";
          package = pkgs.catppuccin-cursors.mochaLavender;
          size = 12;
        };
      };

      home.packages = with pkgs; [
        brightnessctl
      ];

      wayland.windowManager.hyprland.settings = {
        misc = {
          disable_hyprland_logo = true;
        };


        general = {
          gaps_in = 10;
          gaps_out = 20;
          border_size = 2;
          "col.inactive_border" = "rgb(1e1e2e)";
          "col.active_border" = "rgb(f5c2e7)";
        };

        decoration = {
          rounding = 20;

          drop_shadow = true;
          shadow_range = 30;
        };

        animations = {
          enabled = true;

          bezier = [
            "myBezier, 0.10, 0.9, 0.1, 1.05"
          ];

          animation = let
            enabled = "1";
            duration = "1.5";
            curve = "myBezier";
          in [
            "windows, ${enabled}, ${duration}, ${curve}, popin 80%"
            "windowsOut, ${enabled}, ${duration}, ${curve}, popin 80%"
            "border, ${enabled}, ${duration}, ${curve}"
            "borderangle, ${enabled}, ${duration}, ${curve}"
            "borderangle, ${enabled}, ${duration}, ${curve}"
            "fade, ${enabled}, ${duration}, ${curve}"
            "workspaces, ${enabled}, ${duration}, ${curve}"
          ];
        };
      };
    };
  };
}
