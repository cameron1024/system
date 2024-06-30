{machine, ...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      colors = with machine.colorscheme; {
        foreground = base07;
        background = base00;
      };
    };
  };
}
