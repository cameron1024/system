{
  pkgs,
  ...
}: 
{
  home.packages = [pkgs.wezterm];
  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
  xdg.desktopEntries."wezterm-fish" = {
    name = "Wezterm Fish";
    exec = "wezerm start fish";
  };
}
