{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./neovim
    ./neovim-env.nix
    ./shell
    ./languages
  ];

  home.packages = with pkgs;
    [
      imagemagick
      mermaid-cli
      ghostscript
      d2
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      speedread
    ];
}
