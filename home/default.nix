{
  inputs,
  pkgs,
  config,
  ...
}: {
  imports = [
    inputs.mac-app-util.homeManagerModules.default
    ./internet
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

  home.homeDirectory = "/home/${config.home.username}"; 

  home.packages = with pkgs; [
    appimage-run
    pureref
    zmk-studio
  ];
}
