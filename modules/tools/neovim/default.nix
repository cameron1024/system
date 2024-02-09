{ pkgs, username, isDarwin, ... }:
let
   
  lldbAdapter = pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter;

  linuxPackages = with pkgs;[
    neovide
  ];

  macosPackages = [];

in
{
  home-manager.users.${username} = {
    
    home.packages = with pkgs; [
      neovim

      nil  # nix lsp
      lua-language-server
      # lldb
      # lldbAdapter

    ] ++ (if isDarwin then macosPackages else linuxPackages); 

    home.file."./.config/nvim/" = {
      source = ./nvim;
      recursive = true;
    };

    # home.sessionVariables = {
    #   LIBLLDB_PATH = "${lldbAdapter}/lib/libcodelldb.so";
    #   CODELLDB_PATH = "${lldbAdapter}/bin/codelldb";
    # };

  };
}
