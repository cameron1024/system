{
  pkgs,
  machine,
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
  ];

  macosPackages = [];

  extraPackages =
    if machine.linux
    then linuxPackages
    else macosPackages;
in {
  imports = [
    ./lsps.nix
    # ./inlyne.nix
  ];
  config = {
    home.shellAliases = {
      "e" = "nvim";
    };
    home.packages = with pkgs;
      [
        neovim

        neovide
        tree-sitter

        libgit2
        lua5_1

        gcc

        ripgrep
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
