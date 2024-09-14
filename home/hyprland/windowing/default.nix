{pkgs, lib, machine, ...}: {
  imports = [
    ./overview.nix
    ./hy3.nix
    # ./switcher.nix
  ];

  home.packages = lib.mkIf machine.linux [
    pkgs.google-chrome
  ];

  wayland.windowManager.hyprland = {
    extraConfig = ''
      bind=SUPER,R,submap,resize

      submap=resize

      binde=,h,resizeactive,20 0
      binde=,l,resizeactive,-20 0
      binde=,k,resizeactive,0 -20
      binde=,j,resizeactive,0 20

      binde=SHIFT,h,resizeactive,40 0
      binde=SHIFT,l,resizeactive,-40 0
      binde=SHIFT,k,resizeactive,0 -40
      binde=SHIFT,j,resizeactive,0 40

      bind=,escape,submap,reset

      submap=reset
    '';
    settings = {
      bind = [
        "SUPER, q, killactive"

        "SUPER, return, exec, kitty"
        "SUPER SHIFT, return, exec, google-chrome-stable"

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

        "SUPER, f, fullscreen"
        "SUPER SHIFT, f, togglefloating"
        "SUPER, p, pin"

        "SUPER, Backspace, togglespecialworkspace"
      ];

      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      gestures = {
        workspace_swipe = true;
      };

      dwindle.no_gaps_when_only = false;
    };
  };
}
