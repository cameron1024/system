{ username, pkgs, ... }:

{
  home-manager.users.${username} = {
    services.mako = {
      enable = true;
      backgroundColor = "#313244";
      borderRadius = 10;
      font = "FiraCode Nerd Font";
      defaultTimeout = 5000;
    };

    home.packages = with pkgs; [
      swaynotificationcenter
    ];
  };
}
