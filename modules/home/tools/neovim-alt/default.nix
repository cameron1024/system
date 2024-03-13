{
  pkgs,
  isDarwin,
  ...
}: let
  lldbAdapter = pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter;

  linuxPackages = with pkgs; [
    neovide
  ];

  macosPackages = with pkgs; [
    gnome-epub-thumbnailer

  ];
in {
  imports = [
    ./lsps.nix
    ./inlyne.nix
  ];
  config = {
    home.packages = with pkgs;
      [
        neovim-nightly

        # Terminal graphics
        chafa
        imagemagick
        ffmpegthumbnailer
        poppler
        fontpreview

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
