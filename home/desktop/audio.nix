{pkgs, ...}: {
  home.packages = with pkgs; [euphonica];

  services.mpd.enable = true;
}
