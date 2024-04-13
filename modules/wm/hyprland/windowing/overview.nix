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
        inputs.hyprspace.packages.${pkgs.system}.Hyprspace
      ];

      settings = {
        bind = [
          "SUPER, tab, hyprexpo:expo, toggle"

          # seems to be broken atm
          # "SUPER, grave, overview:toggle"
        ];

        plugin = {
          hyprexpo = {
            colums = 3;
            gap_size = 5;
          };
        };
      };
    };
  };
}
