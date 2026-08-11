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
    "zha"
  ];
in
  with lib; {
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

        # customComponents = with pkgs.home-assistant-custom-components; [
        #   dreo
        # ];

        config = {
          default_config = {};
          mobile_app = {};
          api = {};
          logger.default = "info";

          # Accept requests forwarded by the local Caddy reverse proxy
          # (http://home.lan); HA rejects proxied requests otherwise.
          http = {
            use_x_forwarded_for = true;
            trusted_proxies = ["127.0.0.1" "::1"];
          };
        };
      };

      # `openFirewall` only opens TCP 8123. Auto-discovery of ESPHome/Apollo
      # (and other) devices happens over mDNS (multicast 224.0.0.251:5353), so
      # HA's built-in zeroconf listener needs UDP 5353 open or inbound
      # announcements are dropped and devices never surface for discovery.
      networking.firewall.allowedUDPPorts = [5353];
    };
  }
