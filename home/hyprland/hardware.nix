{pkgs, ...}: {
  home.packages = with pkgs; [
    brightnessctl
    pulseaudio
    
  ];

  wayland.windowManager.hyprland.settings = {
    bind = [
      ",XF86MonBrightnessDown, exec, brightnessctl set 10%-"
      ",XF86MonBrightnessUp, exec, brightnessctl set 10%+"
      ",XF86AudioLowerVolume, exec, pactl set-sink-volume 0 -5%"
      ",XF86AudioRaiseVolume, exec, pactl set-sink-volume 0 +5%"
      ",XF86AudioMute, exec, pactl set-sink-mute 0 toggle"
    ];
  };
}
