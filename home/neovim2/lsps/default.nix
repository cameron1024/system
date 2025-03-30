{pkgs, ...}: {
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
    kotlin-language-server

    alejandra # nix formatter

    # (pkgs.callPackage ./iwe.nix {})
  ];
}
