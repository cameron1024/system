{ pkgs, username, ... }:
{
  home-manager.users.${username} = {
    home.packages = with pkgs; [
      neovim

      nil  # nix lsp
      lua-language-server
    ]; 

    home.file."./.config/nvim/" = {
      source = ./nvim;
      recursive = true;
    };
  };
}
