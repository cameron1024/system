{
  pkgs,
  username,
  inputs,
  ...
}: {
  config.home-manager.users.${username} = {
    wayland.windowManager.hyprland = {
      plugins = [
        inputs.hyprland-plugins.packages.${pkgs.system}.hyprexpo
      ];

      settings = {
        bind = [
          "SUPER, grave,      hyprexpo:expo, toggle"
          "SUPER, mouse_up,   hyprexpo:expo, on"
          "SUPER, mouse_down, hyprexpo:expo, off"
        ];
      };
    };
  };
}
