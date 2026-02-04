{
  pkgs,
  lib,
  ...
}: {
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = with pkgs;
      [
        vlc
      ]
      ++ (
        if (pkgs.system == "x86_64-linux")
        then [
          # remarkable desktop is windows app
          wineWowPackages.stable
          bottles
          rmapi
        ]
        else []
      );
  };
}
