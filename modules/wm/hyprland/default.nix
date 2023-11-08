{ pkgs, ... }:

{

  imports = [
    ./lock
  ];

  config = {
    programs.hyprland.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk 
        # xdg-desktop-portal-hyprland 
      ];
    };

    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    home-manager.users.cameron = {

      home.packages = with pkgs; [
        rofi

      ];

      services.mako.enable = true;

      wayland.windowManager.hyprland = {
        enable = true;
        settings = {

          
          monitor = [
            "eDP-1,1920x1200@60,0x0,1"
          ];

          input = {
            kb_layout = "gb";
            kb_options = "ctrl:nocaps";  # caps lock becomes a second ctrl
          };

          animations = {
            enabled = true;
            bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

            animation = [
              "windows, 1, 4, myBezier"
              "windowsOut, 1, 4, default, popin 80%"
              "border, 1, 5, default"
              "borderangle, 1, 5, default"
              "borderangle, 1, 5, default"
              "fade, 1, 4, default"
              "workspaces, 1, 5, default"
            ];
          };

          bind = [
            "SUPER, q, killactive"

            "SUPER, return, exec, wezterm"
            "SUPER, space, exec, rofi -show drun"

            "SUPER, h, movefocus, l"
            "SUPER, j, movefocus, d"
            "SUPER, k, movefocus, u"
            "SUPER, l, movefocus, r"

            "SUPER SHIFT, h, movewindow, l"
            "SUPER SHIFT, j, movewindow, d"
            "SUPER SHIFT, k, movewindow, u"
            "SUPER SHIFT, l, movewindow, r"

            "SUPER, 1, workspace, 1"
            "SUPER, 2, workspace, 2"
            "SUPER, 3, workspace, 3"
            "SUPER, 4, workspace, 4"
            "SUPER, 5, workspace, 5"
            "SUPER, 6, workspace, 6"
            "SUPER, 7, workspace, 7"
            "SUPER, 8, workspace, 8"
            "SUPER, 9, workspace, 9"

            "SUPER SHIFT, 1, movetoworkspace, 1"
            "SUPER SHIFT, 2, movetoworkspace, 2"
            "SUPER SHIFT, 3, movetoworkspace, 3"
            "SUPER SHIFT, 4, movetoworkspace, 4"
            "SUPER SHIFT, 5, movetoworkspace, 5"
            "SUPER SHIFT, 6, movetoworkspace, 6"
            "SUPER SHIFT, 7, movetoworkspace, 7"
            "SUPER SHIFT, 8, movetoworkspace, 8"
            "SUPER SHIFT, 9, movetoworkspace, 9"

            "SUPER, s, togglespecialworkspace, magic"
            "SUPER SHIFT, s, movetoworkspace, special:magic"
          ];

          bindm = [
            "SUPER, mouse:272, movewindow"
            "SUPER, mouse:273, resizewindow"
          ];
        };
      };
    };

  };
}
