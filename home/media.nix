{
  pkgs,
  lib,
  ...
}: {
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = with pkgs; [
      vlc

      # remarkable desktop is windows app
      wineWowPackages.stable
      rmapi
    ];
  };
}
