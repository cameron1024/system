{pkgs, lib, ...}: {
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = with pkgs; [euphonica yt-dlp];

    services.mpd.enable = true;
  };
}
