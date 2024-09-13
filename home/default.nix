{pkgs, ... }: {
  
  imports = [
    ./neovim
    ./hyprland
    ./shell
    ./terminal
    ./languages

    ./communication.nix
  ];

  nixpkgs.config.allowUnfree = true;
  home.stateVersion = "24.05";
}
