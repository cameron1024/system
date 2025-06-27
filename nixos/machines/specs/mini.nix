{inputs}: {
  hostname = "mini";
  cpuArch = "znver5";

  linux = true;
  wm.hyprland.enable = true;

  user = (import ../users.nix).cameron;
  colorscheme = (import ../colors.nix).everforest;
  displays = with (import ../displays.nix); [
    alien
    # benq
    lg
  ];
  wallpapers = with (import ../wallpapers.nix); [
    # everforest
    # leaves
    # mistForest
    # forestBridge
    forestFromSky
  ];
}
