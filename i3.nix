{ config, pkgs, ... }:
let
  mod = "Mod4";
in
{
  home.packages = with pkgs; [
    font-awesome-ttf
    intel-gpu-tools
  ];

  xsession.windowManager.i3 = {
    enable = true;
    config = {
      startup = [
        { command = "exec hsetroot -solid '#002b36'"; always = true; notification = false; }
        { command = "exec setxkbmap -layout pl"; always = true; notification = false; }
        { command = "exec $HOME/dev/dotfiles/nixos/i3/battery-popup.sh"; always = false; notification = false; }
        { command = "exec xdg-mime default org.gnome.Evince.desktop application/pdf"; always = false; notification = false; }
        { command = "exec ${pkgs.autorandr}/bin/autorandr -c"; always = false; notification = false; }
      ];

      window = {
        hideEdgeBorders = "horizontal";
        titlebar = false;
        border = 0;
      };

      workspaceLayout = "tabbed";
      bars = [
        {
          position = "top";
          colors.background = "#001e26";
          colors.statusline = "#708183";
          fonts = {
            names = [ "Fira Code Nerd Font" ];
            size = 10.0;
          };

          trayOutput = "primary";
        }
      ];

      modifier = mod;
      keybindings = {
        "${mod}+Shift+e" = "exec i3-msg exit";
        "${mod}+Shift+c" = "reload";
        "${mod}+Shift+d" = "exec ${pkgs.grobi}/bin/grobi update";
        "${mod}+Shift+r" = "restart";
        "${mod}+Shift+l" = "exec physlock -d";
        "${mod}+Return" = "exec i3-sensible-terminal";

        "XF86AudioRaiseVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "XF86AudioLowerVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@  -5%";
        "XF86AudioMute" = "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@  toggle";
        "XF86AudioMicMute" = "exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@  toggle";

        "XF86MonBrightnessUp" = "exec light -s sysfs/backlight/intel_backlight -A 5";
        "XF86MonBrightnessDown" = "exec light -s sysfs/backlight/intel_backlight -U 5";

        "Print" = "exec ${pkgs.gnome3.gnome-screenshot}/bin/gnome-screenshot -i";

        "${mod}+r" = "exec ${pkgs.rofi}/bin/rofi -show combi -combi-modi window#run#ssh -modi combi";
        "${mod}+c" = "exec ${pkgs.clipmenu}/bin/clipmenu";
        "${mod}+q" = "kill";
        "${mod}+f" = "fullscreen toggle";

        "${mod}+h" = "focus left";
        "${mod}+j" = "focus down";
        "${mod}+k" = "focus up";
        "${mod}+l" = "focus right";

        "${mod}+1" = "workspace 1";
        "${mod}+2" = "workspace 2";
        "${mod}+3" = "workspace 3";
        "${mod}+4" = "workspace 4";
        "${mod}+5" = "workspace 5";
        "${mod}+6" = "workspace 6";
        "${mod}+7" = "workspace 7";
        "${mod}+8" = "workspace 8";
        "${mod}+9" = "workspace 9";
        "${mod}+0" = "workspace 10";

        "${mod}+Shift+1" = "move container to workspace 1";
        "${mod}+Shift+2" = "move container to workspace 2";
        "${mod}+Shift+3" = "move container to workspace 3";
        "${mod}+Shift+4" = "move container to workspace 4";
        "${mod}+Shift+5" = "move container to workspace 5";
        "${mod}+Shift+6" = "move container to workspace 6";
        "${mod}+Shift+7" = "move container to workspace 7";
        "${mod}+Shift+8" = "move container to workspace 8";
        "${mod}+Shift+9" = "move container to workspace 9";
        "${mod}+Shift+0" = "move container to workspace 10";

        "${mod}+Ctrl+Left" = "move workspace to output left";
        "${mod}+Ctrl+Right" = "move workspace to output right";
        "${mod}+Ctrl+Up" = "move workspace to output up";
        "${mod}+Ctrl+Down" = "move workspace to output down";
      };

    };
  };

}
