{ hyprland, headless, ... }:

let 
  wm = if hyprland then ./hyprland else ./gnome;
in

{
  imports = if headless then [] else [ wm ];
}
