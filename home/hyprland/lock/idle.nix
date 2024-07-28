{pkgs, ...}: {
  services.hypridle = {
    enable = true;
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
