{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
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
    ./zed.nix
  ];

  home.homeDirectory = lib.mkDefault "/home/${config.home.username}";
  home.stateVersion = lib.mkDefault "25.05";

  home.packages = with pkgs; (
    if pkgs.stdenv.isLinux
    then [
      appimage-run
      pureref
      zmk-studio
      rakudo
    ]
    else []
  );
}
