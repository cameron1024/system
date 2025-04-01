{pkgs, ...}: let
  cedarVim = pkgs.vimUtils.buildVimPlugin {
    name = "vim-cedar";
    src = pkgs.fetchFromGitHub {
      owner = "Dzordzu";
      repo = "vim-cedar";
      rev = "bf1d782abb557a4297e005f4bf6f9e81b60cce94";
      hash = "sha256-Wh2LvTRjVf2pyRwvQFQD+FIOG9XU/ojjN8Ec8FwlSsI=";
    };
  };
in {
  programs.nixvim.extraPlugins = [cedarVim];
}
