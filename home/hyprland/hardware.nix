{
  pkgs,
  machine,
  ...
}: {
  home.packages =
    if machine.linux
    then [pkgs.brightnessctl pkgs.pulseaudio]
    else [];

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "blueman-applet"
    ];

    bind = [
      ",XF86MonBrightnessDown, exec, brightnessctl set 10%-"
      ",XF86MonBrightnessUp, exec, brightnessctl set 10%+"
      ",XF86AudioLowerVolume, exec, pactl set-sink-volume 0 -5%"
      ",XF86AudioRaiseVolume, exec, pactl set-sink-volume 0 +5%"
      ",XF86AudioMute, exec, pactl set-sink-mute 0 toggle"
    ];
  };
}
