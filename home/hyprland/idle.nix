{
  services.hypridle = {
    enable = true;
    settings = {
      lock_cmd = "hyprlock";
      before_sleep_cmd = "hyprlock";

      listener = [
        {
          timeout = 300;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
