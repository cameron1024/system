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
    };

    services.mpd.enable = true;
    services.mpd.user = "cameron";
    systemd.services.mpd.environment = {
      # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/609
      # User-id must match above user. MPD will look inside this directory for the PipeWire socket.
      XDG_RUNTIME_DIR = "/run/user/${toString config.users.users.cameron.uid}";
    };
    services.mpd.extraConfig = ''
      audio_output {
        type "pipewire"
        name "Pipewire"
      }
    '';
  };
}
