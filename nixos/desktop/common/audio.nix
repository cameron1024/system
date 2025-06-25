{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.services'.desktop.enable {
    environment.systemPackages = [pkgs.pavucontrol];

    services.pulseaudio.enable = false;
    services.pulseaudio.support32Bit = true;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };
}
