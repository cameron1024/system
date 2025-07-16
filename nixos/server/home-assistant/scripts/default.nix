{
  config,
  lib,
  ...
}: let
  devices = {
    apollo = {
      device_id = "83f2de43d9da62e1a826934660f78f4a";
      co2_sensor_entity_id = "a6bf25e2c54b3a9a91b118f968ad8661";
      led_entity_id = "99acb85504924f2cdd0a1e4975f40a09";
      zone_3_occupancy_entity_id = "1a28a1a604d639a3b526376298374087";
    };
  };
  # alias: New automation
  # description: ""
  # triggers:
  #   - type: occupied
  #     device_id: 83f2de43d9da62e1a826934660f78f4a
  #     entity_id: 1a28a1a604d639a3b526376298374087
  #     domain: binary_sensor
  #     trigger: device
  # conditions: []
  # actions:
  #   - type: turn_on
  #     device_id: 83f2de43d9da62e1a826934660f78f4a
  #     entity_id: 99acb85504924f2cdd0a1e4975f40a09
  #     domain: light
  # mode: single
in
  with lib; {
    config = mkIf config.services'.home-assistant.enable {
      services.home-assistant.config = {
        "automation cameron_office_presence" = {
          triggers = [
            {
              type = occupied;
              device_id = devices.apollo.device_id;
              entity_id = devices.apollo.zone_3_occupancy_entity_id;
            }
          ];
        };
      };
    };
  }
