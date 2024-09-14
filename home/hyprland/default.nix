{
  pkgs,
  inputs,
  machine,
  ...
}: {
  imports = [
    ./bar
    ./lock
    ./animations.nix
    ./displays.nix
    ./hardware.nix
    ./input.nix
    ./launcher.nix
    ./notifications.nix
    ./widgets
    ./windowing
    ./wallpaper
    ./screenshot.nix
  ];

  config = {
    wayland.windowManager.hyprland = {
      enable = pkgs.system != "aarch64-darwin";
      xwayland.enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };

    home.packages = with pkgs;
      if machine.wm.hyprland.enable
      then [
        inputs.hypr-utils.packages.${pkgs.system}.default

        xdg-utils
        acpi

        wl-clipboard
      ]
      else [];

    programs.obs-studio.enable = machine.linux;

    xdg.enable = machine.wm.hyprland.enable;

    gtk = {
      enable = machine.wm.hyprland.enable;

      theme.name = "Everforest-Dark-BL";
      theme.package = pkgs.everforest-gtk;

      font.name = "Fira Sans";
      font.package = pkgs.fira;

      cursorTheme.name = "Graphite dark Cursors";
      cursorTheme.package = pkgs.graphite-cursors;
    };
  };
}
