{pkgs, ...}: {
  services.system76-scheduler.enable = true;
  services.power-profiles-daemon.enable = true;
}
