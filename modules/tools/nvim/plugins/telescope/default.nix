{ pkgs, lib, config, ... }:

{
  programs.neovim.plugins = [
    {
      plugin = pkgs.vimPlugins.telescope-nvim;
      config = ''
      lua << EOF
      ${builtins.readFile ./config.lua}
      EOF
      '';
    }
  ];
}
