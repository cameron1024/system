{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    clock24 = true;
    mouse = true; 
    keyMode = "vi";
    escapeTime = 0;
    sensibleOnTop = true;
    shell = pkgs.nushell;
  };
}
