{ pkgs }:

pkgs.vimUtils.buildVimPlugin {
  pname = "silicon";
  version = "0.0.1";
  src = pkgs.fetchFromGitHub {
    owner = "krivahtoo";
    repo = "silicon.nvim";
    rev = "f79aec473007903f8a03c4578d9c0b359f92359a";
    sha256 = "sha256-XuPj77CX1JTzWMGMOXhdKG3FwIAJuJkUjlSSQBzM7lY=";
  };
}
