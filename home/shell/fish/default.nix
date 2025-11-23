{
  pkgs,
  config,
  lib,
  ...
}: let
  macExtras = ''
    eval (/opt/homebrew/bin/brew shellenv)
  '';
  usersDir =
    if pkgs.stdenv.isLinux
    then "home"
    else "Users";
in {
  programs.fish = {
    enable = true;

    shellAbbrs = config.home.shellAliases;

    interactiveShellInit =
      ''
        set fish_greeting
        fish_default_key_bindings
        set -x DIRENV_LOG_FORMAT ""

        fish_add_path ~/.cargo/bin

        set -gx PATH $PATH "$HOME/.puro/bin"
        set -gx PATH $PATH "$HOME/.puro/shared/pub_cache/bin"
        set -gx PATH $PATH "$HOME/.puro/envs/default/flutter/bin"

        set -gx PURO_ROOT "/${usersDir}/cameron/.puro"
        set -gx PUB_CACHE "/${usersDir}/cameron/.puro/shared/pub_cache"
      ''
      + (
        if pkgs.stdenv.isLinux
        then ""
        else macExtras
      );
  };
  home.packages = with pkgs.fishPlugins; [
    gruvbox
    autopair
    forgit
  ];
}
