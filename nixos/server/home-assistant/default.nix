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
          button = ids.homeAssistant.entities.buttons.livingRoomLight;
          target = ids.homeAssistant.entities.helpers.livingRoomLightsTarget;
          lastColor = ids.homeAssistant.entities.helpers.livingRoomMainLastColor;

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
              lights = lights'.office.room;
            })
            # Living room: lights = (presence AND target). The Hue button
            # toggles the *target*, not the lights, so vacancy always wins and
            # re-entry restores whatever was intended. No lux gate here: the
            # target is explicit human intent, so it shouldn't be second-guessed
            # by ambient light.
            {
              id = "living_room_lights_apply";
              alias = "Living room lights follow presence and target";
              mode = "restart";
              triggers = [
                {
                  trigger = "state";
                  entity_id = sensors.livingRoom.presence;
                  to = ["on" "off"];
                }
                {
                  trigger = "state";
                  entity_id = target;
                  to = ["on" "off"];
                }
              ];
              actions = [
                {
                  "if" = [
                    {
                      condition = "state";
                      entity_id = sensors.livingRoom.presence;
                      state = "on";
                    }
                    {
                      condition = "state";
                      entity_id = target;
                      state = "on";
                    }
                  ];
                  # Bare turn_on: Hue bulbs restore their last state, i.e.
                  # "whatever the last scene was".
                  "then" = [
                    {
                      action = "light.turn_on";
                      target.entity_id = lights'.livingRoom.room;
                    }
                  ];
                  "else" = [
                    {
                      action = "light.turn_off";
                      target.entity_id = lights'.livingRoom.room;
                    }
                  ];
                }
              ];
            }
            {
              id = "living_room_button_toggles_target";
              alias = "Living room button toggles lights target";
              mode = "single";
              triggers = [
                {
                  trigger = "state";
                  entity_id = button;
                }
              ];
              conditions = [
                {
                  condition = "template";
                  # The event entity's state changes on every button event;
                  # only act on short_release (long-press stays free for
                  # future use).
                  value_template = "{{ trigger.to_state is not none and trigger.to_state.attributes.event_type == 'short_release' }}";
                }
              ];
              actions = [
                {
                  action = "input_boolean.toggle";
                  target.entity_id = target;
                }
              ];
            }
            {
              id = "living_room_led_shows_target";
              alias = "Living room radar LED shows lights target";
              mode = "restart";
              triggers = [
                {
                  trigger = "state";
                  entity_id = target;
                  to = ["on" "off"];
                }
                # No `to`/`from`: fires on attribute-only changes too, so the
                # LED tracks the main light's colour live.
                {
                  trigger = "state";
                  entity_id = lights'.livingRoom.main;
                }
                # Re-sync the LED after HA restarts.
                {
                  trigger = "homeassistant";
                  event = "start";
                }
              ];
              actions = [
                # Remember the main light's colour whenever it has one (i.e.
                # whenever it's on), so the LED can keep mirroring it while
                # the light is off.
                {
                  "if" = [
                    {
                      condition = "template";
                      value_template = "{{ state_attr('${lights'.livingRoom.main}', 'hs_color') is not none }}";
                    }
                  ];
                  "then" = [
                    {
                      action = "input_text.set_value";
                      target.entity_id = lastColor;
                      data.value = "{{ state_attr('${lights'.livingRoom.main}', 'hs_color') | to_json }}";
                    }
                  ];
                }
                {
                  choose = [
                    {
                      conditions = [
                        {
                          condition = "state";
                          entity_id = target;
                          state = "on";
                        }
                      ];
                      sequence = [
                        {
                          action = "light.turn_on";
                          target.entity_id = sensors.livingRoom.led;
                          data = {
                            # Live colour if the main light is on, else its
                            # last remembered colour, else warm white (before
                            # any colour has ever been seen).
                            hs_color = "{% set saved = states('${lastColor}') %}{{ state_attr('${lights'.livingRoom.main}', 'hs_color') or (saved | from_json if saved not in ['unknown', 'unavailable', ''] else [40, 60]) }}";
                            brightness_pct = 20;
                            transition = 1;
                          };
                        }
                      ];
                    }
                  ];
                  default = [
                    {
                      action = "light.turn_off";
                      target.entity_id = sensors.livingRoom.led;
                    }
                  ];
                }
              ];
            }
          ];

          # Backing store for the living room lights target; state is restored
          # across HA restarts.
          input_boolean.living_room_lights_target = {
            name = "Living room lights target";
            icon = "mdi:lightbulb-auto";
          };

          # Last non-empty hs_color of the living room main light, as JSON.
          # Written by the LED automation; restored across restarts.
          input_text.living_room_main_light_last_color = {
            name = "Living room main light last colour";
            icon = "mdi:palette";
          };

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

          # NOTE: HTTP settings (port, listen addresses, trusted proxies for
          # the local Caddy reverse proxy, X-Forwarded-For) are no longer
          # YAML-configurable: HA migrated them into UI-managed storage
          # (Settings -> System -> Network). The firewall rule below assumes
          # the port stays at the default 8123.
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

      # TCP 8123: the HA frontend (upstream removed `openFirewall` since the
      # port is no longer knowable at eval time; 8123 is the default and we
      # don't override it). Auto-discovery of ESPHome/Apollo (and other)
      # devices happens over mDNS (multicast 224.0.0.251:5353), so HA's
      # built-in zeroconf listener needs UDP 5353 open or inbound
      # announcements are dropped and devices never surface for discovery.
      networking.firewall.allowedTCPPorts = [8123];
      networking.firewall.allowedUDPPorts = [5353];
    };
  }
