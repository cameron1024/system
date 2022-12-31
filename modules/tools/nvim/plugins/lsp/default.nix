{ pkgs, ... }:

{
  programs.neovim.plugins = with pkgs.vimPlugins; [
    {
      plugin = nvim-lspconfig;
      config = ''
      lua << EOF
      ${builtins.readFile ./lspconfig.lua}
      EOF
      '';
    }
    {
      plugin = fidget-nvim;
      config = "lua require 'fidget'.setup {}";
    }
    {
      plugin = trouble-nvim;
      config = "lua require 'trouble'.setup {}";
    }
  ];
}
