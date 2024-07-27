{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
with lib; let
  cfg = config.machine.wm.hyprland;
in {
  imports = [
    ./sound.nix
    ./wifi
    ./bluetooth
  ];

  config = mkIf cfg.enable {
    programs.hyprland.enable = true;
    # programs.hyprland.package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    services.blueman.enable = true;
    services.power-profiles-daemon.enable = true;
  };
}
