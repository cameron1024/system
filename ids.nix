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
  };
}
