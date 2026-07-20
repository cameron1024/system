# A bunch of stuff that "standard machines" (i.e. PCs, laptops, etc.) need, but
# we don't want on anything more specialized (e.g. a RPi)
{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options = {
    services'.standardMachine.enable = mkEnableOption "standard machine config";
    services'.standardMachine.zenKernel = mkEnableOption "zen kernel";
  };
  config = mkIf config.services'.standardMachine.enable {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.grub.memtest86.enable = true;
    boot.loader.timeout = 1;

    boot.kernelPackages =
      if config.services'.standardMachine.zenKernel
      then pkgs.linuxPackages_zen
      else pkgs.linuxPackages_latest;

    hardware.enableAllFirmware = true;
    hardware.enableRedistributableFirmware = true;

    # Firmware updates via LVFS (fwupdmgr). Needed e.g. to pick up Framework
    # BIOS/PD updates such as the UCSI 2.0 + PD firmware fixes in 3.05 that
    # get Type-C DisplayPort Alt Mode working with video Expansion Cards.
    services.fwupd.enable = true;

    networking.networkmanager.enable = true;
  };
}
