{
  config,
  lib,
  ...
}: {
  options = with lib.options; {
    services'.adguardhome = {
      enable = mkEnableOption "AdGuard Home";
    };
  };

  config = lib.mkIf config.services'.adguardhome.enable {
    services.adguardhome = {
      enable = true;
      openFirewall = true;
      mutableSettings = false;
      port = 4909; # changing this seems to have no effect
      host = "0.0.0.0";
    };
  };
}
