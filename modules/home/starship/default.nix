{ pkgs, ... }:

{
  programs.starship.enable = true;
  programs.starship.settings = {
    nix_shell.format = "$symbol";
  };
}
