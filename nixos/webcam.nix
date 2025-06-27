{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options = {
    hardware'.webcam.enable = mkEnableOption "webcam";
  };
  config = mkIf config.hardware'.webcam.enable {
    hardware.ipu6.enable = true;
    hardware.ipu6.platform = "ipu6ep";
  };
}
