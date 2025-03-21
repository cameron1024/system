{
  hostname = "mini";
  boot = "/boot";

  linux = true;
  wm.hyprland.enable = true;

  user = (import ../users.nix).cameron;
  colorscheme = (import ../colors.nix).everforest;
  displays = with (import ../displays.nix); [
    benq
    lg
  ];
  wallpapers = with (import ../wallpapers.nix); [
    everforest
    leaves
    mistForest
    forestBridge
  ];
}
