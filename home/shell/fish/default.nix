{
  pkgs,
  config,
  lib,
  machine,
  ...
}: let
  macExtras = ''
    eval (/opt/homebrew/bin/brew shellenv)
  '';
in {
  programs.fish = {
    enable = true;

    # use `home.shellAliases` as abbreviations instead of aliases
    shellAliases = lib.mkForce {};
    shellAbbrs = config.home.shellAliases;

    interactiveShellInit =
      ''
        fish_default_key_bindings
        set -x DIRENV_LOG_FORMAT ""

        fish_add_path ~/.cargo/bin
      ''
      + (
        if machine.linux
        then ""
        else macExtras
      );
  };
  home.packages = with pkgs.fishPlugins; [
    gruvbox
    autopair
    forgit
    fzf
  ];
}
