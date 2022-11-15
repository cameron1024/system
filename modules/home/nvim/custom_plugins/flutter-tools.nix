{ pkgs }:

pkgs.vimUtils.buildVimPlugin {
  pname = "flutter-tools";
  version = "0.0.1";
  src = pkgs.fetchFromGitHub {
    owner = "akinsho";
    repo = "flutter-tools.nvim";
    rev = "bca467f43d40b1a8ab15341b7c3d9d76bb3c88fb";
    sha256 = "sha256-H487B0/GTc6wxsQgkCEDp2J93QKfylw2utvwHwtk/Fc=";
  };
}
