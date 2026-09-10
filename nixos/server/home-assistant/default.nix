{
  pkgs,
  config,
  lib,
  ...
}: let
  ids = import ../../../ids.nix;

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

        customComponents = with pkgs.home-assistant-custom-components; [
          zone-mapper
        ];

        customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
          zone-mapper-card
        ];

        config = let
          sensors = ids.homeAssistant.entities.sensors;
          lights' = ids.homeAssistant.entities.lights;

          # Turn a room's lights on when presence is detected (and it's dark),
          # off when the room is vacated.
          lightsFollowPresence = {
            slug, # used for the automation id/alias, e.g. "office"
            name, # human-readable room name for the alias
            presence,
            lux,
            lights,
          }: {
            id = "${slug}_lights_follow_presence";
            alias = "${name} lights follow presence";
            mode = "restart";
            triggers = [
              {
                trigger = "state";
                entity_id = presence;
                to = "on";
                id = "occupied";
              }
              {
                trigger = "state";
                entity_id = presence;
                to = "off";
                id = "vacated";
              }
            ];
            actions = [
              {
                choose = [
                  {
                    conditions = [
                      "{{ trigger.id == 'occupied' }}"
                      {
                        condition = "template";
                        # Only light the room when it's actually dark (<50 lux,
                        # tune to taste). Fails open: if the sensor is
                        # unavailable/unknown, presence alone turns the lights on.
                        value_template = "{{ states('${lux}') in ['unavailable', 'unknown'] or states('${lux}') | float(0) < 50 }}";
                      }
                    ];
                    sequence = [
                      {
                        action = "light.turn_on";
                        target.entity_id = lights;
                      }
                    ];
                  }
                  {
                    conditions = "{{ trigger.id == 'vacated' }}";
                    sequence = [
                      {
                        action = "light.turn_off";
                        target.entity_id = lights;
                      }
                    ];
                  }
                ];
              }
            ];
          };
        in {
          # Keep UI-editable automations alongside the Nix-managed ones below.
          "automation ui" = "!include automations.yaml";
          "automation nix" = [
            (lightsFollowPresence {
              slug = "office";
              name = "Office";
              presence = sensors.office.presence;
              lux = sensors.office.light;
              lights = lights'.office;
            })
            (lightsFollowPresence {
              slug = "living_room";
              name = "Living room";
              presence = sensors.livingRoom.presence;
              lux = sensors.livingRoom.light;
              lights = lights'.livingRoom;
            })
          ];

          default_config = { };
          mobile_app = {};
          api = {};
          logger.default = "info";

          # Register a NixOS-managed YAML dashboard as a sidebar entry; its
          # contents come from `lovelaceConfig` below (written to
          # ui-lovelace.yaml). Overrides the module's default "Overview" title.
          lovelace.dashboards.nixos-lovelace = {
            mode = "yaml";
            filename = "ui-lovelace.yaml";
            title = "Zone Mapper";
            icon = "mdi:radar";
            show_in_sidebar = true;
          };

          # Accept requests forwarded by the local Caddy reverse proxy
          # (http://home.lan); HA rejects proxied requests otherwise.
          http = {
            use_x_forwarded_for = true;
            trusted_proxies = ["127.0.0.1" "::1"];
          };
        };

        lovelaceConfig = {
          title = "Zone Mapper";
          views = [
            {
              title = "Zone Mapper";
              path = "zone-mapper";
              icon = "mdi:radar";
              cards = [
                {
                  type = "custom:zone-mapper-card";
                  location = ids.homeAssistant.locations.office;
                }
              ];
            }
          ];
        };
      };

      # `openFirewall` only opens TCP 8123. Auto-discovery of ESPHome/Apollo
      # (and other) devices happens over mDNS (multicast 224.0.0.251:5353), so
      # HA's built-in zeroconf listener needs UDP 5353 open or inbound
      # announcements are dropped and devices never surface for discovery.
      networking.firewall.allowedUDPPorts = [5353];
    };
  }
