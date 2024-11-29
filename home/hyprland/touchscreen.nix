{pkgs, ...}: {
  wayland.windowManager.hyprland = {
    plugins = with pkgs.hyprlandPlugins; [
      hyprgrass
    ];
  };
}
