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
      ++ (lib.optionals ((pkgs.system == "x86_64-linux") [
        # remarkable desktop is windows app
        wineWowPackages.stable
        rmapi
      ]));
  };
}
