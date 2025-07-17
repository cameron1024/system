{
  inputs,
  pkgs,
  config,
  lib,
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

  home.homeDirectory = lib.mkDefault "/home/${config.home.username}";
  home.stateVersion = lib.mkDefault "25.05";

  home.packages = with pkgs; (
    if pkgs.stdenv.isLinux
    then [
      appimage-run
      pureref
      zmk-studio
    ]
    else []
  );
}
