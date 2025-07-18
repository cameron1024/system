{lib, config, ...}:
with import ../constants.nix;
with lib;
{
  config = mkIf config.services'.home-assistant.enable {
    serives.home-assistant.config = {
      template = [
        {
          trigers = [];
          sensor = [];
        }
      ];
    }; 
  };
}
