{ username, ... }:

{
  home-manager.users.${username} = {
    services.mako = {
      enable = true;
      backgroundColor = "313244";
    };
  };
}
