{pkgs, ...}: {
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

  programs.hyprlock = {
    enable = true;
    settings = {
      backgrounds = [
        {
          monitor = "";
          path = "";
          color = "rgb(000000)";
        }
      ];
    };
  };

  services.caffeine.enable = true;
  home.packages = with pkgs; [caffeine-ng];

  wayland.windowManager.hyprland.settings = {
    bind = [
      "SUPER, escape, exec, hyprlock"
    ];
  };
}
