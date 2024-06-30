{config, ...}: {
  programs.nushell = {
    enable = true;
    shellAliases = config.home.shellAliases;
  };
}
