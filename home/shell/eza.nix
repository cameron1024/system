{config, ...}: {
  programs.eza = {
    enable = true;
    icons = true;
    git = true;

    enableFishIntegration = config.programs.fish.enable;
  };

  home.shellAliases = {
    "ls" = "exa -la";
  };
}
