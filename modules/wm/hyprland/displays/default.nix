{ pkgs, username, displays, ... }:

let
  formatDisplayString = display: with display; "${name},${resolution}@${toString refreshRate},${position},${toString scale}";
in

{
  home-manager.users.${username} = {
    home.packages = with pkgs; [ kanshi brightnessctl ];
    
    wayland.windowManager.hyprland.settings = {
      monitor = map formatDisplayString displays;
    };
  };
}
