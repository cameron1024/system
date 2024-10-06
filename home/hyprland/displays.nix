{machine, ...}: let
  formatDisplayString = display: with display; "${name},${resolution}@${toString refreshRate},${position},${toString scale}";
  realMonitors = map formatDisplayString machine.displays;
in {
  wayland.windowManager.hyprland.settings = {
    monitor =
      realMonitors
      ++ [
        # workaround for https://github.com/hyprwm/Hyprland/issues/5958
        "Unknown-1, disable"
      ];
  };
}
