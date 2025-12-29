{
  inputs,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [television];
  programs.fish.interactiveShellInit = ''
    tv init fish | source
  '';
  # programs.television.settings = {
  #   shell_integration.keybindings.command_history = "";
  # };
  # programs.television.package =
  #   inputs.television.packages.${pkgs.system}.default;
}
