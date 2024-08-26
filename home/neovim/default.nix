{pkgs, ...}: let
  linuxPackages = with pkgs; [
    chafa
    imagemagick
    ffmpegthumbnailer
    poppler
    fontpreview
    gnome-epub-thumbnailer

    silicon
  ];

  macosPackages = [];
in {
  imports = [
    ./lsps
    # ./inlyne.nix
  ];
  config = {
    home.shellAliases = {
      "e" = "nvim";
    };

    home.sessionVariables = {
      "EDITOR" = "nvim";
    };

    home.packages = with pkgs;
      [
        neovim

        neovide
        tree-sitter

        libgit2
        lua5_1
        luajitPackages.magick

        gcc

        ripgrep

        mermaid-cli
        imagemagick
        unzip

        typst
        tinymist
      ]
      ++ linuxPackages;

    home.file."./.config/nvim/" = {
      source = ./nvim;
      recursive = true;
    };

    home.sessionVariables = {
      LIBGIT2_PATH = "${pkgs.libgit2}";
    };
  };
}
