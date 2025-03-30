{
  pkgs,
  machine,
  inputs,
  ...
}: let
  linuxPackages = with pkgs; [
    chafa
    imagemagick
    ffmpegthumbnailer
    poppler
    fontpreview
    gnome-epub-thumbnailer

    silicon
    gcc
    neovide
  ];

  macosPackages = [];

  extraPackages =
    if machine.linux
    then linuxPackages
    else macosPackages;
in {
  imports = [
    ./lsps
    ./symbols.nix
  ];
  config = {
    home.shellAliases = {
      "e" = "nvim";
      "ed" = "neovide . &";
    };

    home.sessionVariables = {
      "EDITOR" = "nvim";
      "MANPAGER" = "nvim +Man!";
    };

    home.packages = with pkgs;
      [
        inputs.neovim-nightly-overlay.packages.${pkgs.system}.default

        tree-sitter

        libgit2
        lua5_1
        luajitPackages.magick
        imagemagick

        ripgrep

        mermaid-cli
        d2
        unzip

        typst
        tinymist

        pandoc # required for feed.nvim
        w3m
      ]
      ++ extraPackages;

    home.file."./.config/nvim/" = {
      source = ./nvim;
      recursive = true;
    };

    home.sessionVariables = {
      LIBGIT2_PATH = "${pkgs.libgit2}";
    };
  };
}
