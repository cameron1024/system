{
  hostname = "thinkchad";
  boot = "/boot";
  wm.hyprland.enable = true;

  user = (import ../users.nix).cameron;
  colorscheme = (import ../colors.nix).everforest;
  displays = [
    (import ../displays.nix).thinkpadBuiltin
  ];
  wallpapers = [
    (import ../wallpapers.nix).everforest
  ];
}
