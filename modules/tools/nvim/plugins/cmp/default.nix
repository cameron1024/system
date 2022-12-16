{ pkgs, ... }:

{
  programs.neovim.plugins = with pkgs.vimPlugins; [
    
    nvim-autopairs

    nvim-cmp
    cmp-nvim-lsp
    cmp-path
    cmp-buffer
    cmp_luasnip # nice underscore
    luasnip
    cmp-emoji

    {
      plugin = nvim-cmp; 
      config = ''
      set completeopt=menu,menuone,noselect
      lua << EOF
      ${builtins.readFile ./config.lua}
      EOF
      '';
    }

  ];
}
