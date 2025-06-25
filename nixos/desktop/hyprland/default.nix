{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./sound.nix
    ./bluetooth
  ];

  config = lib.mkIf false {
    programs.hyprland = {
      enable = true;
      # withUWSM = true;
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
