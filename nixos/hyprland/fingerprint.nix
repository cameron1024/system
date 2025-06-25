{
  config,
  lib,
  ...
}:
with lib; {
  options = {
    services'.fingerprint.enable = mkEnableOption "fingerprint services";
  };
  config = mkIf (config.services'.fingerprint.enable) {
    services.fprintd.enable = true;
    systemd.services.fprintd = {
      wantedBy = ["multi-user.target"];
      serviceConfig.Type = "simple";
    };
  };
  # systemd.services.fingerprintResumeFix = let
  #   targets = [
  #     "suspend.target"
  #     "hibernate.target"
  #     "hybrid-sleep.target"
  #     "suspend-then-hibernate.target"
  #   ];
  # in {
  #   enable = true;
  #
  #   unitConfig = {
  #     Description = "Restart fingerprint on resume from suspend";
  #   };
  #
  #   after = targets;
  #   wantedBy = targets;
  #
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStar = "systemctl restart open-fprintd.service python3-validity.service";
  #   };
  # };
}
