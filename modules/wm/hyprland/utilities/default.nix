{ pkgs, username, ... }:

{
  environment.systemPackages = with pkgs; [
    blueman
    networkmanagerapplet  
  ];



  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings = {
      exec-once = [
        "nm-applet --indicator"
        "blueman-applet"
      ];
    };
  };
}
