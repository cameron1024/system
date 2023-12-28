{ username, ... }:

{
  home-manager.users.${username} = {
    programs.wlogout = {
      enable = true;
      style = ./style.css;
      layout = [
        { label = "lock"; text = ""; action = "swaylock"; }
        { label = "shutdown"; text = ""; action = "systemctl poweroff"; }
        { label = "reboot"; text = ""; action = "systemctl reboot"; }
      ];
    };

    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER SHIFT, q, exec, wlogout"
      ];
    };
  };
}
