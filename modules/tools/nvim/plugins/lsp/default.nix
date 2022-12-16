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
  ];
}
