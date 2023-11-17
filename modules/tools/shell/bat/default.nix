{ username, ... }:

{
  home-manager.users.${username} = {
    programs.bat = {
      enable = true;
    };

    programs.nushell = {
      shellAliases = {
        cat = "bat";
      };
    };
  };
}
