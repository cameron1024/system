{ lib, isDarwin, ... }:

{
  programs.tmate = {
    enable = true;
  };

  xdg.desktopEntries = lib.mkIf (!isDarwin) {
    kitty-tmate = {
      name = "kitty-fish";
      exec = "kitty fish";
    };
  };
}
