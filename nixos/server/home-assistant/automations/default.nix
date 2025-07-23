{
  config,
  lib,
  ...
}:
with import ../constants.nix;
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
            domain = "light";
            type = "turn_on";
            device_id = devices.hue.cameron_office.device_id;
            entity_id = devices.hue.cameron_office.entity_id;
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
            for.seconds = 10;
          }
        ];
        conditions = [];
        actions = [
          {
            domain = "light";
            type = "turn_off";
            device_id = devices.hue.cameron_office.device_id;
            entity_id = devices.hue.cameron_office.entity_id;
          }
        ];
      };

      "automation cameron_office_high_co2_phone_alert" = {
        mode = "single";
        alias = "Cameron's Office High CO2 Phone Alert";
        triggers = [
          {
            trigger = "device";
            type = "carbon_dioxide";
            device_id = devices.apollo.device_id;
            entity_id = devices.apollo.co2_sensor_entity_id;
            domain = "sensor";
            above = 800;
          }
        ];
        conditions = [
          {
            condition = "device";
            domain = "binary_sensor";
            type = "is_occupied"; 
            device_id = devices.apollo.device_id;
            entity_id = devices.apollo.zone_3_occupancy_entity_id;
          } 
        ];
        actions = [
          {
            type = "notify";
            domain = "mobile_app";
            device_id = devices.pixel9.device_id;
            message = "The CO2 level in your office is currently {{ trigger.to_state.state }} ppm.";
            title = "High CO2 in your office";
          }
        ];
      };

      "automation cameron_office_co2_light_high" = {
        mode = "single";
        alias = "Cameron's Office CO2 Light (high)";
        triggers = [
          {
            trigger = "device";
            type = "carbon_dioxide";
            device_id = devices.apollo.device_id;
            entity_id = devices.apollo.co2_sensor_entity_id;
            domain = "sensor";
            above = 800;
          }
        ];
        conditions = [];
        actions = [
          {
            action = "light.turn_on";
            metadata = {};
            data.rgb_color = [255 0 0];
            data.brightness_pct = 100;
            target.device_id = devices.apollo.led_entity_id;
          }
        ];
      };

      "automation cameron_office_co2_light_low" = {
        mode = "single";
        alias = "Cameron's Office CO2 Light (low)";
        triggers = [
          {
            trigger = "device";
            type = "carbon_dioxide";
            device_id = devices.apollo.device_id;
            entity_id = devices.apollo.co2_sensor_entity_id;
            domain = "sensor";
            below = 800;
          }
        ];
        conditions = [];
        actions = [
          {
            action = "light.turn_on";
            metadata = {};
            data.rgb_color = [0 255 0];
            data.brightness_pct = 100;
            target.device_id = devices.apollo.led_entity_id;
          }
        ];
      };
    };
  };
}
