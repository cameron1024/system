{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.machine.wm.hyprland;
in {
  config = mkIf cfg.enable {
    programs.hyprland.enable = true;
    services.hypridle
  };
}
