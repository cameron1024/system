{
  lib,
  isDarwin,
  ...
}: {
  programs.tmate = {
    enable = true;
  };

  xdg.desktopEntries = lib.mkIf (!isDarwin) {
    wezterm-fish = {
      name = "wezterm fish";
      exec = "wezterm start fish";
    };
  };
}
