{machine, ...}: let
  formatDisplayString = display: with display; "${name},${resolution}@${toString refreshRate},${position},${toString scale}";
in {
  wayland.windowManager.hyprland.settings = {
    monitor = map formatDisplayString machine.displays;
  };
}
