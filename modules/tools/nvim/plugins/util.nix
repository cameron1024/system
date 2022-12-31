{ pkgs, ...}:

{
  programs.neovim.plugins = with pkgs.vimPlugins; [
    vim-surround

    {
      plugin = comment-nvim;
      config = "lua require 'Comment'.setup {}";
    }
  ];
}
