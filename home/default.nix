{inputs, ...}: {
  imports = [
    inputs.mac-app-util.homeManagerModules.default
    ./mac
    ./neovim
    # ./hyprland
    ./niri
    ./shell
    ./terminal
    ./languages

    ./communication.nix
    ./media.nix
  ];

  home.stateVersion = "24.05";
}
