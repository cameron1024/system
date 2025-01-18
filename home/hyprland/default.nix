{
  pkgs,
  inputs,
  machine,
  lib,
  ...
}: {
  imports = [
    ./bar
    ./lock
    ./animations.nix
    ./displays.nix
    ./hardware.nix
    ./touchscreen.nix
    ./input.nix
    ./launcher.nix
    ./notifications.nix
    ./widgets
    ./windowing
    ./wallpaper
    # ./walker.nix
    ./screenshot.nix
    ./quake-term.nix
  ];

  config = lib.mkIf machine.wm.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      # package = inputs.hyprland.packages.${pkgs.system}.hyprland;

      settings = {
        env = ["XCURSOR_SIZE, 24"];
        exec-once = [
          "tmux"
        ];
      };
    };

    home.packages = with pkgs; [
      inputs.hypr-utils.packages.${pkgs.system}.default

      xdg-utils
      acpi

      wl-clipboard

      zed-editor
    ];

    programs.obs-studio.enable = true;

    xdg.enable = true;

    gtk = {
      enable = true;

      theme.name = "Everforest-Dark-BL";
      theme.package = pkgs.everforest-gtk;

      font.name = "Fira Sans";
      font.package = pkgs.fira;

      cursorTheme.name = "Graphite dark Cursors";
      cursorTheme.package = pkgs.graphite-cursors;
    };
  };
}
