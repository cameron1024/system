{ pkgs }:

pkgs.vimUtils.buildVimPlugin {
  pname = "modes-nvim";
  version = "0.0.1";
  src = pkgs.fetchgit {
    url = "https://git.sr.ht/~whynothugo/lsp_lines.nvim";
    rev = "dbfd8e96ec2696e1ceedcd23fd70e842256e3dea";
    sha256 = "sha256-c+MrWKK7ZIcj2XrPruiQLQ1sr3SJWQfzAR+JM5g+kLE=";
  };
}
