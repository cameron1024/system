{pkgs, ...}: {
  wayland.windowManager.hyprland = {
    plugins = with pkgs.hyprlandPlugins; [
      hyprspace
      hyprexpo
    ];

    settings = {
      bind = [
        "SUPER, tab, hyprexpo:expo, toggle"
        "SUPER, grave, overview:toggle"
      ];

      plugin = {
        hyprexpo = {
          colums = 3;
          gap_size = 5;
          enable_gesture = false;
          gesture_fingers = 3;
          gesture_positive = true;
        };

        overview = {
          reverseSwipe = false;
        };
      };
    };
  };
}
