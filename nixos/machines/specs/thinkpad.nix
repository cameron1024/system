{
  hostname = "thinkchad";
  boot = "/boot";

  linux = true;
  wm.hyprland.enable = true;

  user = (import ../users.nix).cameron;
  colorscheme = (import ../colors.nix).everforest;
  displays = [
    (import ../displays.nix).thinkpadBuiltin
  ];
  wallpapers = [
    (import ../wallpapers.nix).everforest
    (import ../wallpapers.nix).leaves
    (import ../wallpapers.nix).mistForest
    (import ../wallpapers.nix).forestBridge
  ];
}
