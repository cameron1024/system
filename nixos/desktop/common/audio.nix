{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.services'.desktop.enable {
    environment.systemPackages = with pkgs; [
      pavucontrol
      mpc
    ];

    services.pulseaudio.enable = false;
    services.pulseaudio.package = pkgs.pulseaudioFull;
    services.pulseaudio.support32Bit = true;
    services.pulseaudio.systemWide = true; # workaround for mpd using a different user

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
      extraConfig.pipewire-pulse."50-stream-restore" = {
        "pulse.cmd" = [
          {
            cmd = "load-module";
            args = "module-stream-restore";
          }
        ];
      };
    };
  };
}
