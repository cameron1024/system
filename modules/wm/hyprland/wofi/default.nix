{ username, ... }:

{
  home-manager.users.${username} = {
    programs.wofi = {
      enable = true;
      style = builtins.readFile ./style.css;
      settings = {
        width = 420;
        height = 530;
        location = "center";
        show = "drun";
        prompt = "Search...";
        filter_rate = 100;
        allow_markup = true;
        no_actions = true;
        halign = "fill";
        orientation = "vertical";
        content_halign = "fill";
        insensitive = true;
        allow_images = true;
        image_size = 40;
        gtk_dark = true;
        term = "wezterm";
      };
    };

    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER, space, exec, wofi"
      ];
    };
  };
}
