{
  pkgs,
  lib,
  osConfig,
  ...
}: let
  desktopEnabled = osConfig.services'.desktop.enable;
  isLaptop = osConfig.services'.desktop.isLaptop;
  oledMitigations = osConfig.services'.desktop.oledMitigations;

  useIdle = desktopEnabled && (isLaptop || oledMitigations.enable);

  # If we're on battery power, always suspend. Otherwise, use the provided mitigation
  laptopScript = pkgs.writeShellScriptBin "on-idle.sh" ''
    if upower -i /org/freedesktop/UPower/devices/line_power_AC* 2>/dev/null | grep -q "online:.*true"; then
        ${oledMitigations}
        exit 0
    fi
    
    systemctl suspend

  '';

  # If it's a laptop, we always want to suspend to save power. On a desktop, we
  # don't care as much. Safe because suspending turns the screen off anyways
  on-timeout =
    if isLaptop
    then "systemctl suspend"
    else oledMitigations.powerOffDisplayCommand;
in {
  config = lib.mkIf (pkgs.stdenv.isLinux && useIdle) {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "hyprlock";
          before_sleep_cmd = "hyprlock";
        };

        listener = [
          {
            timeout = 300;
            inherit on-timeout;
          }
        ];
      };
    };
    services.caffeine.enable = true;
    home.packages = [pkgs.caffeine-ng];
  };
}
