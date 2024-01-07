{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # logitech control software for linux
    solaar
    usbutils
  ];
}
