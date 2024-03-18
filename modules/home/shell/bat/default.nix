{pkgs, ...}: let
  catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "bat";
    rev = "b19bea35a85a32294ac4732cad5b0dc6495bed32";
    hash = "sha256-POoW2sEM6jiymbb+W/9DKIjDM1Buu1HAmrNP0yC2JPg=";
  };
in {
  programs.bat = {
    enable = true;
    themes = {
      "catppuccin-mocha" = {
        src = catppuccin;
        file = "themes/Catppuccin Mocha.tmTheme";
      };
    };
  };

  programs.nushell = {
    shellAliases = {
      cat = "bat";
    };
  };
}
