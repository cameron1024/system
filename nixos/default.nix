{inputs}: let
  mkSystem = {
    system,
    spec,
  }: let
    overlays = [
      (import ../overlays/utils.nix)
    ];

    machine = spec;
    specialArgs = {
      inherit inputs;
      inherit machine;
    };
  in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      inherit specialArgs;

      modules = [
        inputs.home-manager.nixosModules.default
        ./common.nix
        ./hardware/thinkpad.nix
        {
          inherit machine;

          system.stateVersion = "24.11";
          nixpkgs = {
            config.allowUnfree = true;
            overlays = overlays;
          };

          home-manager.useGlobalPkgs = true;
          home-manager.users.cameron = import ../home;
          home-manager.extraSpecialArgs = specialArgs;
        }
      ];
    };
in {
  thinkpad = mkSystem {
    system = "x86_64-linux";
    spec = import ./machines/specs/thinkpad.nix;
  };
}
