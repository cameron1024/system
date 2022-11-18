{ pkgs, ... }:

let
  tunables = import ../../home/tunables.nix;
  colorschemes = import ../../home/colorschemes.nix;
  colors = colorschemes.${tunables.colorscheme};
in
{

  home-manager.users.cameron = {
    xdg.configFile."waybar/config".source = ./config.json;
    xdg.configFile."waybar/style.css".text = (import ./style.nix) colors;
  };

  environment.systemPackages = with pkgs; [
    waybar
  ];
}
