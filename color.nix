{ colorscheme }:

let
  rendered = with (import ./colorschemes.nix).${colorscheme}; {
    base00 = base00;
    base01 = base01;
    base02 = base02;
    base03 = base03;
    base04 = base04;
    base05 = base05;
    base06 = base06;
    base07 = base07;
    base08 = base08;
    base09 = base09;
    base0A = base0A;
    base0B = base0B;
    base0C = base0C;
    base0D = base0D;
    base0E = base0E;
    base0F = base0F;
  };

in

{
  alacritty = with rendered; {
    primary = {
      foreground = base05;
      background = base00;
    };
    cursor = {
      cursor = base05;
      text = base00;
    };
    normal = {
      black = base00;
      red = base08;
      green = base0B;
      yellow = base0A;
      blue = base0D;
      magenta = base0E;
      cyan = base0C;
      white = base05;
    };
    bright = {
      black = base03;
      red = base08;
      green = base0B;
      yellow = base0A;
      blue = base0D;
      magenta = base0E;
      cyan = base0C;
      white = base07;
    };
  };
  nvim = rendered;
  raw = rendered;
  tmux = with rendered; {
    default = {
      background = base01;
      foreground = base05;
    };
    yellow = {
      background = base0A;
      foreground = base01;
    };
    green = {
      background = base0B;
      foreground = base01;
    };
    orange = {
      background = base09;
      foreground = base01;
    };
    red = {
      background = base08;
      foreground = base05;
    };
    blue = {
      background = base0D;
      foreground = base01;
    };
  };
}
