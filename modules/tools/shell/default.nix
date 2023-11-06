{ pkgs, ... }:

{
  
  home-manager.users.cameron = {
    home.packages = with pkgs; [
      neovim

      nil  # nix lsp
    ]; 

    home.file."./.config/nvim/" = {
      source = ./nvim;
      recursive = true;
    };
  };
}
