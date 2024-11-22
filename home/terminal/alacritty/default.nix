{machine, ...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        TERM = "xterm-256color";
      };

      font.normal.family = "Monaspace Neon";

      colors = with machine.colorscheme; {
        primary = {
          foreground = base07;
          background = base00;
        };
      };
    };
  };
}
