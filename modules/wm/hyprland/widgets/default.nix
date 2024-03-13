{pkgs, ...}: {
  home-manager.users.cameron = {
    programs.eww = {
      enable = true;
      package = pkgs.eww-wayland;
      configDir = ./eww;
    };

    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER, b, exec, eww open statusbar --toggle"
        "SUPER, escape, exec, eww open powermenu --toggle"
      ];
    };
  };
}
