{
  pkgs,
  machine,
  lib,
  ...
}: {
  config = lib.mkIf machine.linux {
    home.packages = with pkgs; [
      vlc
    ];
  };
}
