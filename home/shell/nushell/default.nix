{config, ...}: {
  programs.nushell = {
    enable = true;
    shellAliases = config.home.shellAliases;
    configFile.text = /* nu */ ''
      
    '';
  };

  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };
}
