{ username, ... }:

{
  home-manager.users.${username} = {
    services.mako = {
      enable = true;
      backgroundColor = "#313244";
      borderRadius = 10;
      font = "FiraCode Nerd Font";
      defaultTimeout = 10000;
    };
  };
}
