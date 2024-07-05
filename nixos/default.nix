{
  inputs,
  modules,
}: let
  mkSystem = {
    system,
    spec,
  }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      modules =
        modules
        ++ [
          inputs.home-manager.nixosModules.default
          ./common.nix
          ./hardware/thinkpad.nix
          rec {
            machine = spec;

            system.stateVersion = "24.11";
            nixpkgs.config.allowUnfree = true;

            home-manager.extraSpecialArgs = {inherit machine;};
            home-manager.users.cameron = import ../home;
            home-manager.extraSpecialArgs = {
              inherit inputs;
            };
          }
        ];
    };
in {
  thinkpad = mkSystem {
    system = "x86_64-linux";
    spec = import ./machines/specs/thinkpad.nix;
  };
}
