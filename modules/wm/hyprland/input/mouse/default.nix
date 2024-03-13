{
  username,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    libinput
    wev
  ];

  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings = {
      input = {
        touchpad = {
          natural_scroll = true;
        };
      };

      bind = [
        "SUPER, mouse:274, killactive"
      ];
    };
  };
}
