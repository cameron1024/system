{
  pkgs,
  isDarwin,
  ...
}: let
  neovim = pkgs.wrapNeovim pkgs.neovim-nightly {
    extraMakeWrapperArgs = "--prefix LD_LIBRARY_PATH: \"${pkgs.lib.makeLibraryPath [pkgs.libgit2]}\"";
  };

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
  };
}
