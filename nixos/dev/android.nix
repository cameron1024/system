{pkgs, ...}: {
  programs.adb.enable = true;
  users.users."cameron".extraGroups = ["adbusers" "kvm"];
  services.udev.packages = [
    pkgs.android-udev-rules
  ];
}
