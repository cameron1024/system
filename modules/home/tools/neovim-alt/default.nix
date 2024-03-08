{ pkgs, isDarwin, ... }:
let
   
  lldbAdapter = pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter;

  linuxPackages = with pkgs;[
    neovide
  ];

  macosPackages = [];

in
{
  home.packages = with pkgs; [
    neovim-nightly

    # Terminal graphics
    chafa
    imagemagick
    ffmpegthumbnailer
    poppler
    gnome-epub-thumbnailer
    fontpreview

    # LSPs
    nil 
    lua-language-server
    taplo
    yaml-language-server
    nodePackages_latest.vscode-json-languageserver
    inlyne


  ] ++ (if isDarwin then macosPackages else linuxPackages); 

  home.file."./.config/nvim/" = {
    source = ./nvim;
    recursive = true;
  };

  # home.sessionVariables = {
  #   LIBLLDB_PATH = "${lldbAdapter}/lib/libcodelldb.so";
  #   CODELLDB_PATH = "${lldbAdapter}/bin/codelldb";
  # };
}
