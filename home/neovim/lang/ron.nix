{pkgs, ...}: let
  ronVim = pkgs.vimUtils.buildVimPlugin {
    name = "ron.vim";
    src = pkgs.fetchFromGitHub {
      owner = "ron-rs";
      repo = "ron.vim";
      rev = "f749e543975a82e8dd9a6e7df9600a1c098ae800";
      hash = "sha256-8/xJmymtVGVz2avzlamgK1cNflZ3NRL+B3c7xxbI964=";
    };
  };
in {
  extraPlugins = [ronVim];
}
