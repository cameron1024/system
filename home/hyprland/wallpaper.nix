{pkgs, ...}: {
  home.packages = with pkgs; [
    swww
  ];

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # set the clear background even if the daemon is running
      "swww-daemon; swww clear 000000"
    ];
  };
}
