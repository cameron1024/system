{ pkgs, ... }:

let
  toggleBar = pkgs.writeShellScriptBin "toggle-bar" ''
    if eww windows | grep -q '*statusbar'; then
      eww close statusbar
    else
      eww open statusbar
    fi
  '';
in

{
  home-manager.users.cameron = {
    programs.eww = {
      enable = true;
      package = pkgs.eww-wayland;
      configDir = ./eww;
    };

    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER, b, exec, ${toggleBar}/bin/toggle-bar"
      ];
    };

  };
}
