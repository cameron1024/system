{ pkgs, lib, config, ...}:

{
  home.packages = with pkgs; [ wezterm ];
  
  xdg.configFile."wezterm/wezterm.lua".text = ''

  
  ${builtins.readFile ./wezterm.lua}
  '';
}
