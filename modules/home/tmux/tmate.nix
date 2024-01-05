{
  programs.tmate = {
    enable = true;
  };

  xdg.desktopEntries = {
    kitty-tmate = {
      name = "kitty-fish";
      exec = "kitty fish";
    };
  };
}
