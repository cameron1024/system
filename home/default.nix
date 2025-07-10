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
    ./deploy

    ./communication.nix
    ./media.nix
  ];


  home.packages = with pkgs; [
    appimage-run
    pureref
  ];
  
}
