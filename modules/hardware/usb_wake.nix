{ pkgs, lib, ... }: 
let
  shell = pkgs.bash;
in
{
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", RUN+="${shell} -c 'echo enabled > /sys/bus/usb/devices/*/power/wakeup'"
  '';
}
