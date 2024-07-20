{pkgs, ...}: {
  imports = [
    ./bar
    ./animations.nix
    ./displays.nix
    ./hardware.nix
    ./idle.nix
    ./input.nix
    ./launcher.nix
    ./window.nix
    ./wallpaper.nix
    # ./bar.nix
  ];

  config = {
    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    home.packages = with pkgs; [
      xdg-utils
      acpi
    ];

    xdg.enable = true;

    gtk = {
      enable = true;
      theme.name = "gruvbox-dark";
      theme.package = pkgs.gruvbox-dark-gtk;
    };
  };
}
