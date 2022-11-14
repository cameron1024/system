{ pkgs }:

pkgs.vimUtils.buildVimPlugin {
  pname = "git-conflict";
  version = "0.0.1";
  src = pkgs.fetchFromGitHub {
    owner = "akinsho";
    repo = "git-conflict.nvim";
    rev = "910dd6cd2056a9353412d29b0b769de06f59f144";
    sha256 = "sha256-H487B0/GTc6wxsQgkCEDp2J93QKfylw2utvwHwtk/Fc=";
  };
}
