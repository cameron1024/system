{inputs}: let
  mkSystem = {
    system,
    spec,
  }: let
    overlays = [
      (import ../overlays/utils.nix)
    ];
  in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      modules = [
        inputs.home-manager.nixosModules.default
        ./common.nix
        ./hardware/thinkpad.nix
        rec {
          machine = spec;

          system.stateVersion = "24.11";
          nixpkgs = {
            config.allowUnfree = true;
            overlays = overlays;
          };

          home-manager.useGlobalPkgs = true;
          home-manager.users.cameron = import ../home;
          home-manager.extraSpecialArgs = {
            inherit machine;
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
