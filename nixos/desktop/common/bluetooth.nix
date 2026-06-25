{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services'.desktop.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    # Safety net: never let the rfkill state save/restore stall boot or shutdown
    # for the default 90s if a radio ever wedges again. Harmless everywhere, and
    # keeps a flaky controller from holding up the transaction.
    systemd.services.systemd-rfkill.serviceConfig.TimeoutSec = "5s";
  };
}
