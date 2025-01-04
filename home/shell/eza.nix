{
  config,
  pkgs,
  inputs,
  ...
}: {
  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;

    enableFishIntegration = config.programs.fish.enable;
  };

  programs.fish.shellAbbrs = {
    "ls" = "exa -la";
  };

  home.packages = [
    inputs.lla.packages.${pkgs.system}.withProtobuf
  ];
}
