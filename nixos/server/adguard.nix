{
  config,
  lib,
  ...
}: let
  isServer = config.networking.hostName == "mini";
in {
  # move to a dedicated machine
  config = lib.mkIf false {
    services.adguardhome = {
      enable = true;
      openFirewall = true;
      mutableSettings = false;
      port = 4909;  # changing this seems to have no effect
      host = "0.0.0.0";
    };
  };
}
