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

    boot.kernelPackages =
      if config.services'.standardMachine.zenKernel
      then pkgs.linuxPackages_zen
      else pkgs.linuxPackages;

    hardware.enableAllFirmware = true;
    hardware.enableRedistributableFirmware = true;

    networking.networkmanager.enable = true;
  };
}
