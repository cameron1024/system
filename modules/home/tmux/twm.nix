{ pkgs, ... }:

{
  home.packages = [ pkgs.twm ];
  xdg.configFile."twm/twm.yaml".source = ./twm.yaml;
}
