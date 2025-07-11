{
  pkgs,
  lib,
  machine,
  ...
}: let
  gaps_in = 20;
  gaps_out = 30;

  toggleGaps = pkgs.writeShellScriptBin "toggleGaps.sh" ''
    USE_GAPS=$(hypr-utils store cycle gaps true false)

    if [ $USE_GAPS = "true" ]; then
      hyprctl --batch "keyword general:gaps_out ${toString gaps_out}; keyword general:gaps_in ${toString gaps_in}"
    else
      hyprctl --batch "keyword general:gaps_out 0; keyword general:gaps_in 0"
    fi
  '';
in {
  imports = [
    ./overview.nix
    ./hy3.nix
  ];

  home.packages = lib.mkIf pkgs.stdenv.isLinux [
    toggleGaps
    pkgs.google-chrome-stable
  ];

  wayland.windowManager.hyprland = {
    extraConfig = ''
      bind=SUPER,R,submap,resize

      binde=SUPER,=,resizeactive,20 0
      binde=SUPER,-,resizeactive,-20 0
      binde=SUPER SHIFT,=,resizeactive,0 -20
      binde=SUPER SHIFT,-,resizeactive,0 20
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
      general = with pkgs.cams-utils.hyprland; {
        inherit gaps_in gaps_out;
        border_size = 2;
        "col.inactive_border" = mkColor machine.colorscheme.base00;
        "col.active_border" = mkColor machine.colorscheme.base0D;
      };
      bind = [
        "SUPER, q, killactive"
        "SUPER SHIFT, q, exit"

        "SUPER, return, exec, kitty"
        "SUPER SHIFT, return, exec, firefox"

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
        "SUPER, g, exec, ${toggleGaps}/bin/toggleGaps.sh"
        "SUPER SHIFT, f, togglefloating"
        "SUPER, p, pin"
      ];

      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      gestures = {
        workspace_swipe = true;
      };
    };
  };
}
