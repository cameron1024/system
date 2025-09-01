{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options = {
    programs'.niri.enable = mkEnableOption "niri";
  };

  config = mkIf (config.programs'.niri.enable) {
    services'.fingerprint.enable = true;

    services'.tuigreet.enable = true;
    services'.tuigreet.command = mkForce "niri-session";

    services'.desktop.enable = true;
    services'.desktop.oledMitigations.powerOffDisplayCommand = ''
      niri msg action power-off-monitors
    '';

    programs.niri.enable = true;

    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
    services.cpupower-gui.enable = true;

    environment.systemPackages = with pkgs; [
      vulkan-tools
      lutris
      pavucontrol
    ];
  };
}
