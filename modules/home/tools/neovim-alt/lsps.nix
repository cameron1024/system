{
  pkgs,
  naersk,
  ...
}: let
  markdown-oxide = naersk.buildPackage {
    src = pkgs.fetchFromGitHub {
      owner = "Feel-ix-343";
      repo = "markdown-oxide";
      rev = "2755be81f1068d5f4ea1b4516172acbf2016ab49";
      hash = "sha256-TLWvlQ0EXfdBFSMgmA1mkgJ1WYxIfD2Glpvx1n6hZms=";
    };
  };
in {
  home.packages = with pkgs; [
    markdown-oxide

    nil
    lua-language-server
    taplo
    yaml-language-server
    nodePackages_latest.vscode-json-languageserver
    biome # JS
    nls # nickel

    alejandra # nix formatter
  ];
}
