{ pkgs, ... }:

let 
  startupSession = pkgs.writeText "startupSession" ''
    launch tmux
  '';
in
{
  programs.kitty = {
    enable = true;
    font.name = "FiraCode Nerd Font";
    font.size = 12;
    theme = "Catppuccin-Mocha";
    settings = {
      disable_ligatures = "never";
      font_features = "FiraCode-Regular +ss01 +ss02 +ss03 +ss04 +ss05 +ss07 +ss08 +zero +onum";
      startup_session = "${startupSession}";
    };
  };
}
