{
  pkgs,
  config,
  lib,
  ...
}: let
  extraComponents = [
    "analytics"
    "google_translate"
    "met"
    "radio_browser"
    "shopping_list"
    "isal" # fast zlib
    "hue"
    "mobile_app"
    "jellyfin"
    "default_config"
  ];
in
  with lib; {
    options = {
      services'.home-assistant.enable = mkEnableOption "home assistant";
    };

    config = lib.mkIf config.services'.home-assistant.enable {
      services.home-assistant = {
        enable = true;
        package = pkgs.home-assistant.override {
          inherit extraComponents;
        };
        openFirewall = true;
        inherit extraComponents;

        config = {
          defaultConfig = {};
          logger.default = "info";
        };
      };
    };
  }
