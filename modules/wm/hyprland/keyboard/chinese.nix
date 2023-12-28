{ pkgs, username, ... }:

{
  home-manager.users.${username} = {
    home.packages = with pkgs; [
      fcitx5 
    ];

    wayland.windowManager.hyprland = {
      settings = {
        bind = [
          "SUPER ALT, space, exec, hyprctl switchxkblayout"
        ];
      };
    };
  };
}
