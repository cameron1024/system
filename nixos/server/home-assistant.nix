{
  config,
  lib,
  ...
}: let
  isServer = config.networking.hostName == "mini";
in {
  config = lib.mkIf isServer {
    services.home-assistant = {
      enable = true;
      openFirewall = true;
      extraComponents = [
        "analytics"
        "google_translate"
        "met"
        "radio_browser"
        "shopping_list"
        "isal"  # fast zlib
        "hue"
        "mobile_app"
        "jellyfin"
      ];

      config = {
        defaultConfig = {};
      };
    };
  };
}
