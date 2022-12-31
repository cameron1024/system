
{ pkgs, ...}:

{
  programs.neovim.plugins = [
    {
      plugin = pkgs.vimPlugins.toggleterm-nvim;
      config = ''
        lua << EOF
        ${builtins.readFile ./config.lua}
        EOF
      '';
    }
  ];
}
