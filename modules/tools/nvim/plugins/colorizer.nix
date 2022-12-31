{ pkgs, ...}:

{
  programs.neovim.plugins = [
    {
      plugin = pkgs.vimPlugins.nvim-colorizer-lua;
      config = "lua require 'colorizer'.setup {}";
    }
  ];
}
