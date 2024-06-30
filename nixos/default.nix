{
  inputs,
  modules,
  ...
}: {
  thinkpad = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules =
      modules
      ++ [
        ./common.nix
        ./hardware/thinkpad.nix
        rec {
          machine = import ./machines/specs/thinkpad.nix;
          home-manager.extraSpecialArgs = {inherit machine;};
          system.stateVersion = "24.11";
        }
      ];
  };
}
