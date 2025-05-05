{config, ...}: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;

    # enableBashIntegration = false;
    # enableNushellIntegration = config.programs.nushell.enable;
    # enableFishIntegration = config.programs.fish.enable;
  };

  home.shellAliases = {
    "da" = "direnv allow";
    "dr" = "direnv reload";
  };
}
