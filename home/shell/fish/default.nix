{
  pkgs,
  config,
  ...
}: {
  programs.fish = {
    enable = true;
    shellAbbrs = config.home.shellAliases;
  };
  home.packages = with pkgs.fishPlugins; [
    gruvbox
    autopair
    forgit
    fzf
  ];
}
