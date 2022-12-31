{ pkgs, lib, config, ... }:
let
  cfg = config.programs.myNvim;

  runLua = lua: ''
    lua << EOF
    ${lua}
    EOF
  '';

  includeLua = path: runLua (builtins.readFile path);
in
{
  imports = [

    ./plugins/telescope
    ./plugins/cmp
    ./plugins/lsp
    ./plugins/treesitter
    ./plugins/lualine
    ./plugins/rust
    ./plugins/flutter
    ./plugins/term
    ./plugins/neotree

    ./plugins/git.nix
    ./plugins/autosave.nix
    ./plugins/util.nix
    ./plugins/colorizer.nix

    ./colors.nix

    ./plugins/impatient.nix  # this must be last, so it appears at the top of the init.vim
  ];

  options = with lib; {
    programs.myNvim = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      colors = mkOption {
        type = types.attrs;
        default = (import ../../home/colorschemes.nix).gruvbox;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
        impatient-nvim 
        nvim-web-devicons
      ];
      extraConfig = ''
      	${includeLua ./settings.lua}
      	${includeLua ./keybinds.lua}

        augroup highlight_yank
            autocmd!
            au TextYankPost * silent! lua vim.highlight.on_yank { higroup='IncSearch', timeout=200 }
        augroup END
      '';

    };
  };
}
