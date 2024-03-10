{ pkgs, isDarwin, ... }:
let
   
  lldbAdapter = pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter;

  linuxPackages = with pkgs;[
    neovide
  ];

  macosPackages = [];

in
{
  imports = [ 
    ./lsps.nix 
    ./inlyne.nix
  ];
  config = {
    home.packages = with pkgs; [
      neovim-nightly

      # Terminal graphics
      chafa
      imagemagick
      ffmpegthumbnailer
      poppler
      gnome-epub-thumbnailer
      fontpreview

      tree-sitter


    ] ++ (if isDarwin then macosPackages else linuxPackages); 

    home.file."./.config/nvim/" = {
      source = ./nvim;
      recursive = true;
    };
  };
}
