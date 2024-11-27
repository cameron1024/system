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
    bind = [
      "SUPER, g, exec, hypr-utils cycle gaps 10 0"
    ];

    misc = {
      disable_hyprland_logo = true;
    };

    general = with pkgs.cams-utils.hyprland; {
      gaps_in = 10;
      gaps_out = 20;
      border_size = 2;
      "col.inactive_border" = mkColor machine.colorscheme.base00;
      "col.active_border" = mkColor machine.colorscheme.base0D;
    };

    decoration = {
      drop_shadow = true; 
      shadow_range = 50;
      shadow_render_power = 4;
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
