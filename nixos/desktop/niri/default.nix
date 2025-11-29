{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
with lib;
{
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
    programs.niri.package = inputs.niri.packages.${pkgs.system}.default;

    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
    services.cpupower-gui.enable = true;

    # Configure keyd for dual-function caps lock
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings = {
          main = {
            "capslock" = "overload(control, esc)";
            "leftshift+capslock" = "capslock";
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
