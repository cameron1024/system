{ pkgs, username, ... }:
let
  lldb = pkgs.vscode-extensions.vadimcn.vscode-lldb;
in
{
  home-manager.users.${username} = {
    home.packages = with pkgs; [
      neovim

      vimPlugins.telescope-fzf-native-nvim

      nil
      lua-language-server
      lldb
      coursier
      metals
      pyright
    ];

    home.file."./.config/nvim/" = {
      source = ./nvim;
      recursive = true;
    };

    home.sessionVariables = {
      LLDB_LOCATION = "${lldb}";
    };
  };
}
