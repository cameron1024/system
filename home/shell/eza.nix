{config, ...}: {
  programs.eza = {
    enable = true;
    icons = true;
    git = true;

    enableFishIntegration = config.programs.fish.enable;
  };

  programs.fish.shellAbbrs = {
    "ls" = "exa -la";
  };
}
