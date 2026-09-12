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
        led = "light.living_room_living_room_radar_rgb_light";
      };
      # Per-room lights: `room` is the whole room (Hue room group); other
      # keys are specific lights within it.
      lights = {
        office.room = "light.cameron_s_office";
        livingRoom = {
          room = "light.living_room";
          main = "light.hue_color_lamp_1";
        };
      };
      buttons.livingRoomLight = "event.living_room_living_room_switch_button_1";
      helpers.livingRoomLightsTarget = "input_boolean.living_room_lights_target";
      # Last non-empty hs_color of the living room main light, as JSON
      # (e.g. "[40.0, 60.0]"); lets the radar LED mirror it while the light
      # is off. Nix-managed helper, defined in the HA config.
      helpers.livingRoomMainLastColor = "input_text.living_room_main_light_last_color";

    };
  };
}
