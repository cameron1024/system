{
  inputs,
  pkgs,
  ...
}: {
  # wayland.windowManager.hyprland = {
  #   plugins = [inputs.hy3.packages.${pkgs.system}.hy3];
  #
  #   settings = {
  #     bind = [
  #       "SUPER, v, hy3:makegroup, v"
  #       "SUPER, x, hy3:makegroup, h"
  #       "SUPER, s, hy3:changegroup, opposite"
  #     ];
  #
  #     plugin.hy3 = {
  #       autotile = {
  #         enable = true;
  #       };
  #     };
  #   };
  # };
}
