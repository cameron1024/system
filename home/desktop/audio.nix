{pkgs, lib, config, ...}: {
  config = lib.mkIf config.services'.desktop.enable {
    home.packages = with pkgs; [euphonica yt-dlp];

    services.mpd.enable = true;
  };
}
