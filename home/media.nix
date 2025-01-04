{
  pkgs,
  machine,
  lib,
  ...
}: {
  config = lib.mkIf machine.linux {
    home.packages = with pkgs; [
      vlc
      
      # remarkable desktop is windows app
      wineWowPackages.stable
      rmapi
    ];
  };
}
