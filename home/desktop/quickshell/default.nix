{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.programs'.quickshell.enable = mkEnableOption "quickshell";
  config = mkIf config.programs'.quickshell.enable {
    home.packages = [inputs.quickshell.packages.${pkgs.system}.default pkgs.cmake];
  };
}
