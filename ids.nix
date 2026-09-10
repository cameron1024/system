# Central registry of stable identifiers referenced across the configuration.
# Imported directly where needed (e.g. `import ../../../ids.nix`).
{
  homeAssistant = {
    locations = {
      office = "office";
    };

    entities = {
      sensors.office = {
        presence = "binary_sensor.apollo_mtr_1_989d2c_ld2450_presence";
        light = "sensor.apollo_mtr_1_989d2c_ltr390_light";
      };
      sensors.livingRoom = {
        presence = "binary_sensor.living_room_living_room_radar_ld2450_presence";
        light = "sensor.living_room_living_room_radar_ltr390_light";
      };
      lights = {
        office = ["light.cameron_s_office"];
        livingRoom = ["light.living_room"];
      };

    };
  };
}
