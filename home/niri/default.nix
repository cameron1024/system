{
  imports = [
    ../hyprland/launcher.nix
    ../hyprland/bar
  ];
  xdg.configFile."niri/config.kdl".source = ./config.kdl;
}

