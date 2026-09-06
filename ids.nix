# Central registry of stable identifiers referenced across the configuration.
# Imported directly where needed (e.g. `import ../../../ids.nix`).
{
  homeAssistant = {
    # Stable *key* for the Apollo mmWave zone-mapper (not a display name). The
    # card slugifies this to build zone entity ids, so keeping it fixed means
    # the room's display name (HA Area) can change without breaking anything:
    #   sensor.zone_mapper_office_zone_1
    #   binary_sensor.office_zone_1_presence
    locations = {
      office = "office";
    };

    # TODO(automations): replace with the MTR-1's stable device_id once needed,
    # so device/entity renames don't break references.
    # devices.officeAirQuality = "<device_id>";

    # Entity ids referenced by automations.
    entities = {
      sensors.office = {
        # The MTR-1's raw LD2450 radar presence entity (whole-field detection).
        # Switch to the zone-mapper's `binary_sensor.office_zone_N_presence`
        # (created once a zone is drawn on the card) for zone-filtered presence.
        presence = "binary_sensor.apollo_mtr_1_989d2c_ld2450_presence";
        # LTR-390 ambient light (lux) sensor on the MTR-1.
        light = "sensor.apollo_mtr_1_989d2c_ltr390_light";
      };
      # Hue room group for the office (bridge-side broadcast to all members).
      lights.office = ["light.cameron_s_office"];

    };
  };
}
