{
  imports = [./neovim ./hyprland ./shell ./terminal];

  nixpkgs.config.allowUnfree = true;
  home.stateVersion = "24.05";
}
