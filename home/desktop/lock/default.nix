{
  machine,
  pkgs,
  lib,
  osConfig,
  ...
}:
with lib; {
  imports = [./idle.nix];

  config = mkIf (osConfig != null && osConfig.services'.desktop.enable) {
    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER, escape, exec, hyprlock"
      ];
    };

    programs.hyprlock = {
      enable = machine.linux;
      settings = with machine.colorscheme;
      with pkgs.cams-utils.hyprland; {
        general = {
          hide_cursor = true;
          no_fade_in = true;
          no_fade_out = true;
        };

        animation = "fade, 1, 2, default";

        auth.fingerprint.enabled = true;

        background = [
          {
            monitor = "";
            path = "/home/cameron/.wallpaper";
            blur_passes = 3;
            blur_size = 4;
          }
        ];

        input-field = [
          {
            size = "300, 50";
            position = "0, 0";
            monitor = "";
            dots_center = true;
            fade_on_empty = true;
            font_color = mkColor base05;
            inner_color = mkColor base00;
            outer_color = mkColor base0A;
            check_color = mkColor base0C;
            fail_color = mkColor base0E;
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

          common = {
            monitor = "";
            color = mkColor base05;
            font_family = "Fira Sans";
            # font_family = "FiraCode Nerd Font";
          };
        in [
          # time
          (common
            // {
              text = "$TIME";
              text_align = "right";
              font_size = timeHeight;
              valign = "bottom";
              halign = "right";
              position = "-50, ${builtins.toString timeOffset}";
            })

          # date
          (common
            // {
              text = "cmd[update:10000] date +'%A %d/%m/%Y'";
              text_align = "right";
              font_size = dateHeight;
              valign = "bottom";
              halign = "right";
              position = "-50, ${builtins.toString dateOffset}";
            })

          # weather
          (common
            // {
              text = "cmd[update:10000] hypr-utils store cached 'curl wttr.in/London?format=4'";
              text_align = "right";
              font_size = weatherHeight;
              valign = "bottom";
              halign = "right";
              position = "-50, ${builtins.toString weatherOffset}";
            })

          # battery
          (common
            // {
              text = "cmd[update:1000] hypr-utils system battery --num-spaces 3";
              text_align = "right";
              font_size = 18;
              valign = "top";
              halign = "right";
              position = "-50, -50";
            })
        ];
      };
    };
  };
}
