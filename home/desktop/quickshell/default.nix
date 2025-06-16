{
  inputs,
  machine,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf machine.linux {
    home.packages = [inputs.quickshell.packages.${pkgs.system}.default pkgs.cmake];
  };
}
