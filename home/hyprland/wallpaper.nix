{
  pkgs,
  machine,
  ...
}: 
let
  wallpapers = map (wp: wp pkgs) machine.wallpapers;
in
{
  home.packages = with pkgs; [
    swww
  ];

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # set the clear background even if the daemon is running
      "swww-daemon; swww img ${builtins.elemAt wallpapers 0}"
    ];
  };
}
