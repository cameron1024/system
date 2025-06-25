{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services'.desktop.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
}
