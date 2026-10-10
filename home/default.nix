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

      # GUI profiler
      (tracy.overrideAttrs (old: {
        # GCC 16 no longer transitively includes <cstdint>
        postPatch = (old.postPatch or "") + ''
          sed -i '1i #include <cstdint>' server/tracy_robin_hood.h
        '';
      }))
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      appimage-run
      zmk-studio
      wl-clipboard
    ]
    ++ lib.optionals (pkgs.stdenv.isLinux && osConfig != null) [
      pcmanfm
    ];

  programs.obs-studio.enable = true;
}
