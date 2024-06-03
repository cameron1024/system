{
  pkgs,
  inputs,
  username,
  laptop,
  ...
}: {
  services.fprintd.enable = true;

  environment.systemPackages = [
    inputs.hypridle.packages.${pkgs.system}.default
  ];

  security.pam.services.hyprlock = {
    fprintAuth = true;
  };

  home-manager.users.${username} = {
    programs.hyprlock = let
      base = "rgb(1e1e2e)";
      text = "rgb(cdd6f4)";
      accent = "rgb(cba6f7)";
      surface0 = "rgb(313244)";
      red = "rgb(f38ba8)";
      yellow = "rgb(f9e2af)";
      font = "FiraCode Nerd Font";
    in {
      enable = true;

      general = {
        disable_loading_bar = false;
        hide_cursor = true;
        no_fade_in = false;
        no_fade_out = true;
      };

      backgrounds = [
        {
          monitor = "";
          path = "";
          color = base;
        }
      ];

      labels = [
        {
          monitor = "";
          text = ''cmd[update:30000] echo "$(date +"%R")"'';
          color = text;
          font_size = 90;
          font_family = font;
          position = {
            x = -30;
            y = 0;
          };
          halign = "right";
          valign = "top";
        }

        {
          monitor = "";
          text = ''cmd[update:43200000] echo "$(date +"%A, %d %B %Y")"'';
          color = text;
          font_size = 25;
          font_family = font;
          position = {
            x = -30;
            y = -150;
          };
          halign = "right";
          valign = "top";
        }

        {
          monitor = "";
          text = ''cmd[update:1000] battery | cams-home-utilities battery'';
          color = text;
          font_size = 18;
          font_family = font;
          position = {
            x = -30;
            y = -190;
          };
          halign = "right";
          valign = "top";
        }
      ];

      input-fields = [
        {
          monitor = "";
          size = {
            width = 300;
            height = 60;
          };
          outline_thickness = 4;
          dots_size = 0.2;
          dots_spacing = 0.2;
          dots_center = true;
          outer_color = accent;
          inner_color = surface0;
          font_color = text;
          fade_on_empty = false;
          placeholder_text = "Password";
          hide_input = false;
          check_color = accent;
          fail_color = red;
          fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
          capslock_color = yellow;
          position = {
            x = 0;
            y = -35;
          };
          halign = "center";
          valign = "center";
        }
      ];
    };

    services.hypridle = {
      enable = laptop;
      lockCmd = "hyprlock";
      beforeSleepCmd = "hyprlock";
      listeners = [
        {
          timeout = 300;
          onTimeout = "systemctl suspend";
        }
      ];
    };

    wayland.windowManager.hyprland.settings = {
      exec-once = [
        "hypridle"
      ];

      bind = [
        "SUPER, escape, exec, hyprlock"
      ];
    };
  };
}
