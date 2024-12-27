{
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "[workspace special] kitty"
    ];

    bind = [
      "SUPER, backspace, togglespecialworkspace"
    ];

    animation = [
      "specialWorkspace, 1, 2, default, slidefadevert -50%"
    ];

    decoration = {
      dim_special = 0;
    };

    dwindle = {
      special_scale_factor = 1;
    };
  };
}
