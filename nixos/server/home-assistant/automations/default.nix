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
    pixel9 = {
      device_id = "9e4db89ed4e6ef9c7c5042edc89993fa";
    };
  };
in
  with lib; {
    config = mkIf config.services'.home-assistant.enable {
      services.home-assistant.config = {
        "automation cameron_office_presence_occupied" = {
          mode = "single"; 
          alias = "Cameron's Office Occupied";
          triggers = [
            {
              trigger = "device";
              domain = "binary_sensor";
              type = "occupied";
              device_id = devices.apollo.device_id;
              entity_id = devices.apollo.zone_3_occupancy_entity_id;
            }
          ];
          conditions = [];
          actions = [
            {
              type = "turn_on";
              device_id = devices.apollo.device_id;
              entity_id = devices.apollo.led_entity_id;
              domain = "light";
            }
          ];
        };

        "automation cameron_office_presence_clear" = {
          mode = "single"; 
          alias = "Cameron's Office Empty";
          triggers = [
            {
              trigger = "device";
              domain = "binary_sensor";
              type = "not_occupied";
              device_id = devices.apollo.device_id;
              entity_id = devices.apollo.zone_3_occupancy_entity_id;
            }
          ];
          conditions = [];
          actions = [
            {
              type = "turn_off";
              device_id = devices.apollo.device_id;
              entity_id = devices.apollo.led_entity_id;
              domain = "light";
            }
          ];
        };

        "automation cameron_office_high_co2" = {
          mode = "single"; 
          alias = "Cameron's Office High CO2";
          triggers = [
            {
              type = "carbon_dioxide";
              device_id = devices.apollo.device_id;
              entity_id = devices.apollo.co2_sensor_entity_id;
              domain = "sensor";
              trigger = "device";
              above = 800;
            }
          ];
          conditions = [];
          actions = [
            {
              type = "notify";
              domain = "mobile_app";
              device_id = devices.pixel9.device_id;
              message = "The CO2 level in your office is currently";  
              title = "High CO2 in your office";
            }
          ];
        };
      };
    };
  }
