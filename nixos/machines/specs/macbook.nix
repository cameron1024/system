{
  linux = false;
  wm.hyprland.enable = false;

  user = (import ../users.nix).cameron;
  colorscheme = (import ../colors.nix).everforest;
  displays = [];
  wallpapers = with (import ../wallpapers.nix); [
    everforest
    leaves
    mistForest
    forestBridge
  ];
}
