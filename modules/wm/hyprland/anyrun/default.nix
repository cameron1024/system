{
  pkgs,
  username,
  inputs,
  ...
}: {
  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER SHIFT, space, exec, anyrun"
      ];
    };

    programs.anyrun = {
      enable = true;

      config = {
        plugins = with inputs.anyrun.packages.${pkgs.system}; [
          applications
          rink
          shell
          symbols
          translate
        ];

        width.fraction = 0.3;
        y.absolute = 15;
        hidePluginInfo = true;
        closeOnClick = true;
      };

      extraCss = builtins.readFile ./style.css;

      extraConfigFiles."applications.ron".text = ''
        Config(
          desktop_actions: false,
          max_entries: 5,
          terminal: Some("wezterm"),
        )
      '';
    };
  };
}
