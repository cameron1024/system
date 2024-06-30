{pkgs, ...}: {
  imports = [
    ./animations.nix
    ./displays.nix
    ./hardware.nix
    ./idle.nix
    ./input.nix
    ./window.nix
    ./bar.nix
  ];

  config = {
    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    home.packages = with pkgs; [
      xdg-utils
    ];

    xdg.enable = true;
  };
}
