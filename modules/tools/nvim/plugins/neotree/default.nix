
{ pkgs, ... }:

{
  programs.neovim.plugins = [
    {
      plugin = pkgs.vimPlugins.neo-tree-nvim;
      config = ''
      lua << EOF
      ${builtins.readFile ./config.lua}
      EOF
      '';
    }
  ];
}
