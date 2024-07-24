{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.machine;
in {
  config = mkIf cfg.wm.hyprland.enable {
    # networking.wireless.iwd.enable = true;
  };
}
