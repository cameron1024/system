{
  pkgs,
  machine,
  lib,
  ...
}: let
  useIdle = lib.lists.any (display: display.oled) machine.displays;
in {
  services.hypridle = {
    enable = useIdle;
    settings = {
      general = {
        lock_cmd = "hyprlock";
        before_sleep_cmd = "hyprlock";
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  services.caffeine.enable = true;
  home.packages = with pkgs; [caffeine-ng];
}
