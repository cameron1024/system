{ pkgs, username, ... }:

{
  imports = [ ./chinese.nix ];
  config = {
    environment.systemPackages = with pkgs; [
      brightnessctl
      wl-clipboard
    ];

    home-manager.users.${username} = {
      wayland.windowManager.hyprland = {
        settings = {
          input = {
            kb_layout = "gb,cn";
            kb_options = "ctrl:nocaps";  # caps lock becomes a second ctrl

            touchpad = {
              natural_scroll = true;
            };
          };

          exec-once = [
            # disable middle click paste
            # "wl-paste -p --watch wl-copy -p ''"
          ];

          bind = [
            ",XF86MonBrightnessDown, exec, brightnessctl set 10%-"
            ",XF86MonBrightnessUp, exec, brightnessctl set 10%+"
          ];
        };
      };
    };
  };
}
