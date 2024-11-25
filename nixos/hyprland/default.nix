{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.machine.wm.hyprland;
in {
  imports = [
    ./sound.nix
    ./wifi
    ./bluetooth
    # ./power-management.nix
  ];

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      # package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };

    services = {
      blueman.enable = true;
      # power-profiles-daemon.enable = true;
      upower.enable = true;
      cpupower-gui.enable = true;
    };
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };

      pulseaudio.support32Bit = true;
    };

    environment.systemPackages = with pkgs; [
      vulkan-tools
      lutris
    ];
  };
}
