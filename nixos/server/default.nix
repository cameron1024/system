{
  config,
  lib,
  ...
}: let
  isServer = config.networking.hostName == "mini";
in {
  config = lib.mkIf isServer {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };

    services.homebox = {
      enable = true;
      settings = {
        "HBOX_WEB_HOST" = "0.0.0.0";
        "HBOX_OPTIONS_ALLOW_REGISTRATION" = "true";
      };
    };

    services.glance.enable = true;
    services.glance.openFirewall = true;
    services.glance.settings = {
      server.port = 11112;
      server.host = "0.0.0.0";
      theme = {
        background-color = "186 21 20";
        contrast-multiplier = 1.2;
        primary-color = "97 13 80";
      };
    };

    services.polaris = {
      enable = true;
      openFirewall = true;
      port = 5050;
    };
  };
}
