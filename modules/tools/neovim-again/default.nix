{ pkgs, config, lib, ... }:
let
  cfg = config.programs.myNvim;
  lldb = pkgs.vscode-extensions.vadimcn.vscode-lldb;
in
{
  options = with lib; {
    programs.myNvim = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      neovim

      vimPlugins.telescope-fzf-native-nvim

      rnix-lsp
      lua-language-server
      lldb
      coursier
      metals
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
