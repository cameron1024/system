{ pkgs, ... }:

{
  programs.neovim.plugins = [
    {
      plugin = pkgs.vimPlugins.vim-auto-save;
      config = "let g:auto_save = 1";
    }
  ];
}
