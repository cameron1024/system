{
  pkgs,
  config,
  lib,
  ...
}: {
  programs.fish = {
    enable = true;

    # use `home.shellAliases` as abbreviations instead of aliases
    shellAliases = lib.mkForce {};
    shellAbbrs = config.home.shellAliases;

    interactiveShellInit = ''
      fish_vi_key_bindings 
    '';
  };
  home.packages = with pkgs.fishPlugins; [
    gruvbox
    autopair
    forgit
    fzf
  ];
}
