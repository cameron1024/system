{
  pkgs,
  machine,
  ...
}: 
let
  wallpapers = map (wp: wp pkgs) machine.wallpapers;
  firstWallpaper = builtins.elemAt wallpapers 0;
in
{
  home.packages = with pkgs; [
    swww
  ];

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # set the clear background even if the daemon is running
      "swww-daemon; swww img ${firstWallpaper}"
    ];
  };
}
