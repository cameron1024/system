
{ pkgs, ...}:

with pkgs.vimPlugins;

let
  rust-tools = {
      plugin = rust-tools-nvim;
      config = ''
        lua << EOF
          ${builtins.readFile ./config.lua}      
        EOF
      '';
    };

  crates = {
    plugin = crates-nvim;
    config = "lua require 'crates'.setup {}";
  };
in
{
  programs.neovim.plugins = [
    rust-tools
    crates 
  ];
}
