{pkgs, lib, ...}: {
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = with pkgs; [euphonica];

    services.mpd.enable = true;
  };
}
