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

      "automation cameron_office_high_co2" = {
        mode = "single";
        alias = "Cameron's Office High CO2";
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
            type = "notify";
            domain = "mobile_app";
            device_id = devices.pixel9.device_id;
            message = "The CO2 level in your office is currently {{ trigger.to_state.state }} ppm.";
            title = "High CO2 in your office";
          }
        ];
      };
    };
  };
}
