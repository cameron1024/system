{ font, pkgs }:

{
  enable = true;
  keybindings = {
    "f11" = "toggle_fullscreen";
  };
  settings = {
    font_name = font;
  };
}
