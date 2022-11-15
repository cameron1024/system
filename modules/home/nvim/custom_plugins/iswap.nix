{ pkgs }:

pkgs.vimUtils.buildVimPlugin {
  pname = "iswap-nvim";
  version = "0.0.1";
  src = pkgs.fetchFromGitHub {
    owner = "mizlan";
    repo = "iswap.nvim";
    rev = "4f5d0925fd89c04f02fcb7d1f7e8b97b4d6a8a61";
    sha256 = "sha256-xACWTAh+92I7PHZW9H9vsIAlDV1Hhr+l2aCyjoTBCWE=";
  };
}
