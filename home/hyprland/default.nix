{pkgs, ...}: {
  imports = [
    ./animations.nix
    ./displays.nix
    ./hardware.nix
    ./idle.nix
    ./input.nix
    ./window.nix
    ./wallpaper.nix
    ./bar.nix
  ];

  config = {
    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      plugins = [
      ];
    };

    home.packages = with pkgs; [
      xdg-utils
    ];

    xdg.enable = true;

    gtk = {
      enable = true;
      theme.name = "gruvbox-dark";
      theme.package = pkgs.gruvbox-dark-gtk;
    };
  };
}
