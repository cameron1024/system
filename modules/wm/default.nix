{ hyprland, ... }:
{
  imports = [
    (if hyprland then ./hyprland else ./gnome)
  ];
}
