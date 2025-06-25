{
  config,
  lib,
  ...
}:
with lib; let
  desktopEnabled = config.services'.desktop.enable;
  fingerprintEnabled = desktopEnabled && config.services'.fingerprint.enable;
in {
  options = {
    services'.fingerprint.enable = mkEnableOption "fingerprint services";
  };

  config = mkIf fingerprintEnabled {
    services.fprintd.enable = true;
    systemd.services.fprintd = {
      wantedBy = ["multi-user.target"];
      serviceConfig.Type = "simple";
    };
  };
}
