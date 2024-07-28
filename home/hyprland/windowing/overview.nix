{
  inputs,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland = {
    plugins = [
      inputs.hyprland-plugins.packages."${pkgs.system}".hyprexpo
      inputs.hyprspace.packages."${pkgs.system}".Hyprspace
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
