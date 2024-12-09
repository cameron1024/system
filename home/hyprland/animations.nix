{
  machine,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland.settings = let
    enabled = "1";
    duration = "1.5";
    curve = "easeInOutQuint";
  in {
    misc = {
      disable_hyprland_logo = true;
    };


    decoration.shadow = {
      enabled = true;
      # range = 50;
      # render_power = 1;
    };


    bezier = [
      "${curve}, 0.83, 0, 0.17, 1"
    ];

    animation = [
      "windows, ${enabled}, ${duration}, ${curve}"
      "windowsOut, ${enabled}, ${duration}, ${curve}"
      "border, ${enabled}, ${duration}, ${curve}"
      "borderangle, ${enabled}, ${duration}, ${curve}"
      "borderangle, ${enabled}, ${duration}, ${curve}"
      "fade, ${enabled}, ${duration}, ${curve}"
      "workspaces, ${enabled}, ${duration}, ${curve}"
    ];
  };
}
