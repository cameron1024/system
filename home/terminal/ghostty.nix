{
  inputs,
  pkgs,
  lib,
  machine,
  ...
}: {
  config = lib.mkIf machine.linux {
    home.packages = [inputs.ghostty.packages.${pkgs.system}.default];

    xdg.configFile."ghostty/config".text = ''
      theme = Everforest Dark - Hard
      font-family = FiraCode Nerd Font

      confirm-close-surface = false
      window-decoration = false

      initial-command = tmux
    '';
  };
}
