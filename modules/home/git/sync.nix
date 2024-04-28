{pkgs, ...}: let
  src = pkgs.fetchFromGitHub {
    owner = "GitJournal";
    repo = "git-auto-sync";
    rev = "4c47abae959b5ae687292cd4895216377e06fa9f";
    hash = "";
  };

  git-sync = pkgs.buildGoModule {
    inherit src;
    pname = "git-auto-sync";
    version = "0.0.0";
    vendorHash = "";
  };
in {
  # home.packages = [git-sync];
}
