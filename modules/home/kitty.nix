{ font, pkgs }:

{
  enable = true;

  font = {
    name = font;
  };

  settings = {
    disable_ligatures = "never";
    font_features = "FiraCode-Regular +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +zero +onum";
    theme = "gruvbox";
  };

  extraConfig = ''
    confirm_os_window_close -1
  '';
}
