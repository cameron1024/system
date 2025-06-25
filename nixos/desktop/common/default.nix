{
  lib,
  config,
  ...
}:
with lib; {
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./fingerprint.nix
  ];

  options.services'.desktop = let
    numberType = types.oneOf [types.int types.float];
    displayType = types.submodule {
      options = {
        name = mkOption {
          type = types.str;
          description = "The name of the monitor";
          example = "DP-1";
        };

        resolution.width = mkOption {
          type = types.ints.positive;
        };
        resolution.height = mkOption {
          type = types.ints.positive;
        };

        position.x = mkOption {
          type = types.int;
        };
        position.y = mkOption {
          type = types.int;
        };

        refreshRate = mkOption {
          type = numberType;
        };

        scale = mkOption {
          type = numberType;
        };

        oled = mkOption {
          type = types.bool;
          description = "Whether this display is OLED (and therefore requires burn-in mitigation)";
        };
      };
    };
  in {
    enable = mkEnableOption "basic dekstop functionality";

    isLaptop = mkEnableOption {
      type = types.bool;
      default = false;
    };

    displays = mkOption {
      type = types.addCheck (types.listOf displayType) (list: length list > 0);
    };

    oledMitigations.enable = mkOption {
      type = types.bool;
      default = any (display: display.oled) config.services'.desktop.displays;
      description = ''
        Whether to enable burn-in mitigations for OLED screens.
        Defauts to true if there is at least one monitor that is OLED.
      '';
    };
    oledMitigations.powerOffDisplayCommand = mkOption {
      type = types.str;
      description = "A command that will power off the displays";
    };
  };

  config = mkIf config.services'.desktop.enable {
    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;

    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
  };
}
