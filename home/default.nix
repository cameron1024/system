{inputs, pkgs, ...}: {
  imports = [
    inputs.mac-app-util.homeManagerModules.default
    ./firefox
    ./mac
    ./neovim
    ./neovim-env.nix
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
    nixos-generators
    caligula
  ];
  
}
