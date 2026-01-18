{
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
    
    services'.tuigreet.enable = !config.services.displayManager.gdm.enable;
    services'.tuigreet.command = mkForce "niri-session";

    services'.desktop.enable = true;
    services'.desktop.oledMitigations.powerOffDisplayCommand = ''
      niri msg action power-off-monitors
    '';

    programs.niri.enable = true;
    programs.niri.useNautilus = true;

    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
    services.cpupower-gui.enable = true;

    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = ["*"];
        settings = {
          main = {
            "capslock" = "overload(control, esc)";
          };
        };
      };
    };

    environment.systemPackages = with pkgs; [
      vulkan-tools
      lutris
      pavucontrol
    ];
  };
}
