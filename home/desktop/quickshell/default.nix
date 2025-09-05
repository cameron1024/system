{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = [inputs.quickshell.packages.${pkgs.system}.default];
  };
}
