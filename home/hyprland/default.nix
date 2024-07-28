{
  pkgs,
  inputs,
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
    ./widgets
    ./windowing
    ./wallpaper
  ];

  config = {
    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      # package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };

    home.packages = with pkgs; [
      inputs.hypr-utils.packages.${pkgs.system}.default

      xdg-utils
      acpi

      wl-clipboard
    ];

    xdg.enable = true;

    gtk = {
      enable = true;

      theme.name = "Everforest-Dark-BL";
      theme.package = pkgs.everforest-gtk;

      font.name = "Fira Sans";
      font.package = pkgs.fira;
    };
  };
}
