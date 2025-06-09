{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.machine.wm.hyprland;
in {
  config = mkIf cfg.enable {
    hardware.bluetooth.enable = true;

    services.blueman.enable = true;
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;

  };
}
