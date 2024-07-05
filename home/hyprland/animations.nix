{machine, ...}: {
  wayland.windowManager.hyprland.settings = let
    enabled = "1";
    duration = "1.5";
    curve = "easeInOutQuint";
  in {
    misc = {
      disable_hyprland_logo = true;
    };

    general = {
      gaps_in = 10;
      gaps_out = 20;
      border_size = 2;
      "col.inactive_border" = machine.colorscheme.base08;
      "col.active_border" = machine.colorscheme.base09;
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
