{ pkgs, username, ... }:

{
  i18n = {
    inputMethod = {
      enabled = "ibus";
    };
  };

  environment.systemPackages = with pkgs; [
    brightnessctl
    wl-clipboard
    pulseaudio
  ];

  home-manager.users.${username} = {
    wayland.windowManager.hyprland = {
      settings = {
        input = {
          kb_layout = "gb,cn";
          kb_options = "ctrl:nocaps";  # caps lock becomes a second ctrl

        };

        bind = [
          "SUPER ALT, space, exec, hyprctl switchxkblayout logitech-usb-receiver next"

          ",XF86MonBrightnessDown, exec, brightnessctl set 10%-"
          ",XF86MonBrightnessUp, exec, brightnessctl set 10%+"
          ",XF86AudioLowerVolume, exec, pactl set-sink-volume 0 -5%"
          ",XF86AudioRaiseVolume, exec, pactl set-sink-volume 0 +5%"
          ",XF86AudioMute, exec, pactl set-sink-mute 0 toggle"
        ];
      };
    };
  };
}
