{ username, pkgs, naersk, ... }:

let 
  window-switcher = naersk.buildPackage {
    pname = "window_switcher";
    version = "0.2.1";
    src = pkgs.fetchFromGitHub {
      owner = "H3rmt";
      repo = "WindowSwitcher";
      rev = "8299ef4f1c269126fe1e62ad08bfb7c2378a9b39";
      hash = "sha256-DBXn8Jq930ruNBtTO6yg2wlo9cMwgDiLZ1L1VW0OlZM=";
    };
  };

  switch = "${window-switcher}/bin/window_switcher";
in
{
  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings = {
      bind = [
        "ALT, TAB, exec, ${switch}"
        "ALT SHIFT, TAB, exec, ${switch} --reverse"
      ];
    };
  };
}
