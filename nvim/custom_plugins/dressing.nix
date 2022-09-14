{ pkgs }:

pkgs.vimUtils.buildVimPlugin {
  name = "dressing-nvim";
  src = pkgs.fetchFromGitHub {
    owner = "stevearc";
    repo = "dressing.nvim";
    rev = "d886a1bb0b43a81af58e0331fedbe8b02ac414fa";
    sha256 = "sha256-dwj6OJJBwujcvl7Km1PlwiRzGfrVQpVjZdJEmMINobE=";
  };
}
