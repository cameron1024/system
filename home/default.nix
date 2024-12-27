{
  imports = [
    ./mac 
    ./neovim2
    ./hyprland
    ./shell
    ./terminal
    ./languages

    ./communication.nix
    ./media.nix
  ];

  nixpkgs.config.allowUnfree = true;
  home.stateVersion = "24.05";
}
