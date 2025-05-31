{
  lib,
  config,
  ...
}: {
  config = lib.mkIf (config.networking.hostName == "mini") {
    services.avahi.enable = true;
    services.home-assistant = {
      enable = true;
      extraComponents = [
        # Components required to complete the onboarding
        "esphome"
        "met"
        "radio_browser"
      ];
      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = {};
      };
    };
  };
}
