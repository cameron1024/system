{ pkgs }:

pkgs.vimUtils.buildVimPlugin {
  pname = "tree-climber";
  version = "0.0.1";
  src = pkgs.fetchFromGitHub {
    owner = "ziontee113";
    repo = "syntax-tree-surfer";
    rev = "d6d518f48dcc4441b11ee3e6cefd48fa1e09568a";
    sha256 = pkgs.lib.fakeSha256;
  };
}
