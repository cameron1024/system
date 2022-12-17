{ pkgs, ...}:

{
  programs.neovim.plugins = [
    {
      plugin = pkgs.vimPlugins.impatient-nvim;
      config = "lua require 'impatient'";
    }
  ];
}
