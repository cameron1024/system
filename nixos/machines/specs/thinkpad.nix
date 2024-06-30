{
  hostname = "thinkchad";
  boot = "/boot";
  wm.hyprland.enable = true;

  user = (import ../users.nix).cameron;
  colorscheme = (import ../colors.nix).gruvbox;
  displays = [
    (import ../displays.nix).thinkpadBuiltin
  ];
}
