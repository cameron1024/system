{
  inputs,
  pkgs,
  ...
}: let
  # hyprexpo = inputs.hyprland-plugins.packages."${pkgs.system}".hyprexpo.overrideAttrs {
  #   stdenv = pkgs.gcc13Stdenv;
  # };


  
in {
  wayland.windowManager.hyprland = {
    plugins = [
      # inputs.hyprspace.packages.${pkgs.system}.Hyprspace
    ];

    settings = {
      bind = [
        # "SUPER, tab, overview:expo, toggle"
      ];

      # plugin = {
      #   hyprexpo = {
      #     colums = 3;
      #     gap_size = 5;
      #   };
      # };
    };
  };
}
