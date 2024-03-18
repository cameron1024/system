{
  pkgs,
  isDarwin,
  ...
}: let
  lldbAdapter = pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter;

  linuxPackages = with pkgs; [
    neovide

    chafa
    imagemagick
    ffmpegthumbnailer
    poppler
    fontpreview
    gnome-epub-thumbnailer

    silicon
  ];

  macosPackages = with pkgs; [];
in {
  imports = [
    ./lsps.nix
    ./inlyne.nix
  ];
  config = {
    home.packages = with pkgs;
      [
        neovim-nightly
        tree-sitter
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
