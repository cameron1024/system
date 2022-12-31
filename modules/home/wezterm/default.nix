{ pkgs, lib, config, ...}:

let 
  colors = (import ../../home/colorschemes.nix).gruvbox;
in
{
  home.packages = with pkgs; [ wezterm ];
  
  xdg.configFile."wezterm/wezterm.lua".text = with colors; ''
  
  ${builtins.readFile ./wezterm.lua}
  '';
}
