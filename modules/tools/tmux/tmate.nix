{ username, lib, isDarwin, ...}:

{
  home-manager.users.${username} = {
    programs.tmate = {
      enable = true;
    };

    xdg.desktopEntries = lib.mkIf (!isDarwin) {
      kitty-tmate = {
        name = "kitty-fish";
        exec = "kitty fish";
      };
    };
  };
}
