{ pkgs, ... }:
let
  colors = (import ../../../../home/colorschemes.nix).gruvbox;
in
{
  programs.neovim.plugins = with pkgs.vimPlugins; [
    
    aerial-nvim
    {
      plugin = lualine-nvim;
      config = ''
      lua << EOF
      
      local lualine_colors = {
        black        = "${colors.base00}",
        white        = "${colors.base05}",
        red          = "${colors.base08}",
        green        = "${colors.base0B}",
        blue         = "${colors.base0D}",
        yellow       = "${colors.base0A}",
        gray         = "${colors.base04}",
        darkgray     = "${colors.base01}",
        lightgray    = "${colors.base02}",
        inactivegray = "${colors.base03}",
      }

      ${builtins.readFile ./config.lua}
      EOF
      '';
    }
  ];
}
