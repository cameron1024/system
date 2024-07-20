{config, ...}: {
  programs.nushell = {
    enable = true;
    shellAliases = config.home.shellAliases;
  };

  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };
}
