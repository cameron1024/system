{
  pkgs,
  machine,
  ...
}: let
  wallpapers = map (wp: wp pkgs) machine.wallpapers;
  firstWallpaper = builtins.elemAt wallpapers 0;
  # wallpapers = map (wp: wp pkgs) machine.wallpapers;
in {
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
      general = {
        hide_cursor = true;
        no_fade_in = false;
        no_fade_out = false;
      };

      background = [
        {
          monitor = "";
          path = firstWallpaper;
          blur_passes = 3;
          blur_size = 8;
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
