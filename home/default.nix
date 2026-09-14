{
  pkgs,
  inputs,
  config,
  lib,
  osConfig ? null,
  ...
}: {
  imports = [
    inputs.nixvim.homeModules.default
    ./internet
    ./mac
    ./cli.nix
    # ./hyprland
    ./niri

    ./terminal
    ./languages
    ./deploy

    ./communication.nix
    ./media.nix
    ./zed.nix
  ];

  home.homeDirectory = lib.mkDefault "/home/${config.home.username}";
  home.stateVersion = lib.mkDefault "25.05";

  home.shellAliases.nv = "neovide --fork";

  home.packages = with pkgs;
    [
      neovide
      ripdrag
      imagemagick
      mermaid-cli
      ghostscript
      d2
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      appimage-run
      zmk-studio
      rakudo
      speedread
      wl-clipboard
    ]
    ++ lib.optionals (pkgs.stdenv.isLinux && osConfig != null) [
      pcmanfm
    ];

  programs.obs-studio.enable = true;
}
