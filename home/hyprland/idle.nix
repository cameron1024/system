{
  pkgs,
  machine,
  ...
}: let
  wallpapers = map (wp: wp pkgs) machine.wallpapers;
  firstWallpaper = builtins.elemAt wallpapers 0;
in {
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

  programs.hyprlock = {
    enable = true;
    settings = with machine.colorscheme;
    with pkgs.cams-utils.hyprland; {
      general = {
        hide_cursor = true;
        no_fade_in = true;
        no_fade_out = true;
      };

      background = [
        {
          monitor = "";
          path = "${firstWallpaper}";
          blur_passes = 3;
          blur_size = 4;
        }
      ];

      input-field = [
        {
          size = "250, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = true;
          font_color = mkColor base05;
          inner_color = mkColor base00;
          outer_color = mkColor base0A;
          check_color = mkColor base0C;
          fail_color = mkColor base0E;
          # outline_thickness = 1;
          placeholder_text = ''Password...'';
        }
      ];

      label = let
        padding = 20;

        weatherHeight = 18;
        dateHeight = 24;
        timeHeight = 72;

        weatherOffset = 50;
        dateOffset = weatherOffset + weatherHeight + padding;
        timeOffset = dateOffset + dateHeight + padding;
      in [
        {
          monitor = "";
          text = "$TIME";
          text_align = "right";
          font_size = timeHeight;
          color = mkColor base05;
          valign = "bottom";
          halign = "right";
          position = "-50, ${builtins.toString timeOffset}";
          font_family = "Fira Sans";
        }

        {
          monitor = "";
          text = "cmd[update:10000] date +'%A %d/%m/%Y'";
          text_align = "right";
          font_size = dateHeight;
          color = mkColor base05;
          valign = "bottom";
          halign = "right";
          position = "-50, ${builtins.toString dateOffset}";
          font_family = "Fira Sans";
        }

        {
          monitor = "";
          text = "cmd[update:1000] curl wttr.in/London?format=4";
          text_align = "right";
          font_size = weatherHeight;
          color = mkColor base05;
          valign = "bottom";
          halign = "right";
          position = "-50, ${builtins.toString weatherOffset}";
          font_family = "Fira Sans";
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
