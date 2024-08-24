{pkgs, ...}:
# markdown-oxide = naersk.buildPackage {
#   src = pkgs.fetchFromGitHub {
#     owner = "Feel-ix-343";
#     repo = "markdown-oxide";
#     rev = "2755be81f1068d5f4ea1b4516172acbf2016ab49";
#     hash = "sha256-TLWvlQ0EXfdBFSMgmA1mkgJ1WYxIfD2Glpvx1n6hZms=";
#   };
# };
let
  harper = pkgs.callPackage ./harper.nix {};
in {
  home.packages = with pkgs; [
    harper

    markdown-oxide
    # inputs.wgsl-analyzer.packages.${pkgs.system}.default

    marksman
    nil
    nixd
    lua-language-server
    taplo
    yaml-language-server
    nodePackages_latest.vscode-json-languageserver
    biome # JS
    typescript-language-server
    nls # nickel
    # typescript
    lemminx
    nixd
    nodePackages.bash-language-server

    alejandra # nix formatter
  ];
}
