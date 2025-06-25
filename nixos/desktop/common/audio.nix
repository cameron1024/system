{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services'.desktop.enable {
    services.pulseaudio.enable = false;
    services.pulseaudio.support32Bit = true;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };
}
