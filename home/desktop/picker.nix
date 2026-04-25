{
  config,
  lib,
  ...
}:
with lib;
{
  options.services'.desktop.picker = mkOption {
    type = types.str;
    description = ''
      Generic picker. Should be able to pipe arguments into it, dmenu style
    '';
  };

  config = mkIf config.services'.desktop.enable {
    assertions = [
      {
        assertion = config.services'.desktop ? picker && config.services'.desktop.picker != "";
        message = ''
          services'.desktop.picker must be set when desktop is enabled.
        '';
      }
    ];
  };
}
