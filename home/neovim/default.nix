{inputs, ...}: {
  imports = [
    inputs.nixvim.homeManagerModules.default
    {
      programs.nixvim.enable = true;
      programs.nixvim.vimdiffAlias = true;
    }
  ];

  config.programs.nixvim = ./module.nix;
}
