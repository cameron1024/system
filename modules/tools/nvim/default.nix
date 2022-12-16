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
    ./colors.nix

    ./plugins/telescope
    ./plugins/cmp
    ./plugins/lsp
    ./plugins/treesitter
    ./plugins/lualine

    ./plugins/autosave.nix
    ./plugins/neotree.nix
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
      ];
      extraConfig = ''
      	${includeLua ./settings.lua}
      	${includeLua ./keybinds.lua}
      '';

    };
  };
}
