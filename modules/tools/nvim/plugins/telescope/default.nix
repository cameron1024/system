{ pkgs, lib, config, ... }:

{
  programs.neovim.plugins = with pkgs.vimPlugins; [
    telescope-fzf-native-nvim 
    {
      plugin = telescope-nvim;
      config = ''
      lua << EOF
      ${builtins.readFile ./config.lua}
      EOF
      '';
    }
  ];
}
