{inputs}: let
  mkSystem = {
    system,
    spec,
    hardware,
  }: let
    overlays = [
      (import ../overlays/utils.nix)
    ];

    machine = spec // {
      
    };

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
        hardware
        ({lib, ...}: {
          inherit machine;

          system.stateVersion = "24.11";
          nixpkgs = {
            config.allowUnfree = true;
            overlays = overlays;
            # hostPlatform = lib.mkIf (machine.cpuArch != null) {
            #   gcc.arch = machine.cpuArch;
            #   gcc.tune = machine.cpuArch;
            #   system = "x86_64-linux";
            # };
          };

          home-manager.useGlobalPkgs = true;
          home-manager.users.cameron = import ../home;
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.backupFileExtension = "backup";
        })
      ];
    };
in {
  thinkchad = mkSystem {
    system = "x86_64-linux";
    spec = import ./machines/specs/thinkpad.nix { inherit inputs; };
    hardware = ./hardware/thinkpad.nix;
  };

  mini = mkSystem {
    system = "x86_64-linux";
    spec = import ./machines/specs/mini.nix{ inherit inputs; };
    hardware = ./hardware/mini2.nix;
  };
}
