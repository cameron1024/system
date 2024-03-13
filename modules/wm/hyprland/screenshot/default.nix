{
  pkgs,
  username,
  ...
}: {
  environment.systemPackages = with pkgs; [
    hyprshot
  ];

  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER SHIFT, s, exec, hyprshot -m region"
      ];
    };
  };
}
