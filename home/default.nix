{inputs, pkgs, ...}: {
  imports = [
    inputs.mac-app-util.homeManagerModules.default
    ./firefox
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

  home.packages = with pkgs; [
    appimage-run
  ];
  
}
