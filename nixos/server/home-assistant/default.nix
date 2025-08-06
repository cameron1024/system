{
  pkgs,
  config,
  lib,
  ...
}: let
  extraComponents = [
    "analytics"
    "api"
    "cast"
    "default_config"
    "esphome"
    "google_translate"
    "hue"
    "immich"
    "isal" # fast zlib
    "jellyfin"
    "london_air"
    "met"
    "mobile_app"
    "nest"
    "radio_browser"
    "shopping_list"
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
        package = pkgs.home-assistant.override {
          inherit extraComponents;
        };
        openFirewall = true;
        inherit extraComponents;

        customComponents = with pkgs.home-assistant-custom-components; [
          dreo
        ];

        config = {
          default_config = {};
          mobile_app = {};
          api = {};
          logger.default = "info";
        };
      };
    };
  }
