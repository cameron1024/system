{
  pkgs,
  inputs,
  lib,
  ...
}:
with lib; {
  imports = [
    ./bar
    ./lock
    ./otter-launcher
    ./animations.nix
    ./displays.nix
    ./hardware.nix
    ./touchscreen.nix
    ./input.nix
    ./notifications.nix
    ./widgets
    ./windowing
    # ./wallpaper
    # ./walker.nix
    ./screenshot.nix
    ./quake-term.nix
    ./ai.nix
    # ./kando.nix
  ];

  options = {
    programs'.hyprland.enable = mkEnableOption "Hyprland";
  };

  config = lib.mkIf config.programs'.hyprland.enable {
    home.pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
    };
    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      # package = inputs.hyprland.packages.${pkgs.system}.hyprland;

      settings = {
        env = ["XCURSOR_SIZE, 24"];
        exec-once = ["tmux"];
      };
    };

    home.packages = with pkgs; [
      inputs.hypr-utils.packages.${pkgs.system}.default

      xdg-utils
      acpi

      wl-clipboard
    ];

    programs.obs-studio.enable = true;

    xdg.enable = true;
  };
}
