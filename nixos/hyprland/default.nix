{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.machine.wm.hyprland;
in {
  imports = [
    ./sound.nix
  ];


  config = mkIf cfg.enable {
    programs.hyprland.enable = true;
    services.blueman.enable = true;
  };
}
