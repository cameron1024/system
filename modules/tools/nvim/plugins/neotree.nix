{ pkgs, ... }:

{
  programs.neovim.plugins = [
    {
      plugin = pkgs.vimPlugins.neo-tree-nvim;
      config = "lua require 'neo-tree'.setup {}";
    }
  ];
}
