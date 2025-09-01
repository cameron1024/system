{
  inputs,
  pkgs,
  ...
}: {
  programs.television.enable = true;
  programs.television.enableFishIntegration = true;
  # programs.television.settings = {
  #   shell_integration.keybindings.command_history = "";
  # };
  # programs.television.package =
  #   inputs.television.packages.${pkgs.system}.default;
}
