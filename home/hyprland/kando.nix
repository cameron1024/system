{pkgs, ...}: {
  home.packages = with pkgs; [
    kando
  ];

  wayland.windowManager.hyprland.settings = {
    bind = [
      "SUPER, 1, exec, kando -m example-menu"
    ];
  };

  # xdg.configFile."kando/config.json".text = /* json */ ''
  #   {
  #     "enableDarkModeForMenuTHemes": true,
  #     "enableVersionCheck": false
  #   }
  # '';
  #
  # xdg.configFile."kando/menus.json".text = /* json */ ''
  #   {
  #     "menus": [
  #       {
  #         "shortcut": ""
  #       }
  #     ]
  #   }
  # '';
}
