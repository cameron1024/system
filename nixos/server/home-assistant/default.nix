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
    "esphome"
  ];
in
  with lib; {
    imports = [./automations];

    options = {
      services'.home-assistant.enable = mkEnableOption "home assistant";
    };

    config = mkIf config.services'.home-assistant.enable {
      services.home-assistant = {
        enable = true;
        # configWritable = true;
        package = pkgs.home-assistant.override {
          inherit extraComponents;
        };
        openFirewall = true;
        inherit extraComponents;

        config = {
          default_config = {};
          mobile_app = {};

          logger.default = "info";
        };
      };
    };
  }
