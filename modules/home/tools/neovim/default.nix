{
  pkgs,
  isDarwin,
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
in {
  imports = [
    ./lsps.nix
    ./inlyne.nix
  ];
  config = {
    home.packages = with pkgs;
      [
        neovim

        neovide
        tree-sitter

        libgit2
        lua5_1
      ]
      ++ (
        if isDarwin
        then macosPackages
        else linuxPackages
      );

    home.file."./.config/nvim/" = {
      source = ./nvim;
      recursive = true;
    };

    home.sessionVariables = {
      LIBGIT2_PATH = "${pkgs.libgit2}";
    };
  };
}
