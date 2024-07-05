{
  imports = [./neovim ./hyprland ./shell ./terminal ./languages];

  nixpkgs.config.allowUnfree = true;
  home.stateVersion = "24.05";
}
