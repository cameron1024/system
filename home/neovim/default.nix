{inputs, pkgs, ...}: {
  imports = [
    inputs.nixvim.homeModules.default
    {
      programs.nixvim.enable = true;
      programs.nixvim.vimdiffAlias = true;
      programs.nixvim.nixpkgs.pkgs = pkgs;
    }
  ];

  config.programs.nixvim = ./module.nix;
  config.home.packages = with pkgs; [nil nixd];
}
