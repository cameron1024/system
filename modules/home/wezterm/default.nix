{ pkgs, ...}:

{
  home.packages = with pkgs; [ wezterm ];
  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
}
