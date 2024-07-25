{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.machine.wm.hyprland;
in {
  config = mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
}
