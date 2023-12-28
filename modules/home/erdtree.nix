{ pkgs, ... }:

{
  home.packages = [
    pkgs.erdtree
  ];

  xdg.configFile."erdtree/.erdtreerc".text = ''
    -s size
    --disk-usage logical
    --icons
    --prune
  '';
}
