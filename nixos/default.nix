{inputs}: let
  mkSystem = {
    system,
    spec,
    hardware,
    config ? {},
    homeManager ? true,
    optimizations ? true,
  }: let
    overlays = import ../overlays {
      inherit inputs optimizations;
      arch = spec.cpuArch;
    };

    machine = spec;

    specialArgs = {
      inherit inputs;
      inherit machine;
    };
  in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      inherit specialArgs;

      modules =
        [
          ./common.nix
          hardware
          {
            inherit machine;
            system.stateVersion = "24.11";
            nixpkgs.overlays = overlays;
          }
          config
        ]
        ++ (
          if homeManager
          then [
            inputs.home-manager.nixosModules.default
            {
              home-manager.useGlobalPkgs = true;
              home-manager.users.cameron = import ../home;
              home-manager.extraSpecialArgs = specialArgs;
              home-manager.backupFileExtension = "backup";
            }
          ]
          else []
        );
    };
in {
  thinkchad = mkSystem {
    system = "x86_64-linux";
    spec = import ./machines/specs/thinkpad.nix {inherit inputs;};
    hardware = ./hardware/thinkpad.nix;

    config = {
      gpu'.arch = "intel";

      networking.hostName = "thinkchad";

      programs'.niri.enable = true;
      services'.desktop.displays = with import ./machines/displays.nix; [
        thinkpadBuiltin
      ];

      programs.steam.enable = true;
    };
  };

  mini = mkSystem {
    system = "x86_64-linux";
    spec = import ./machines/specs/mini.nix {inherit inputs;};
    hardware = ./hardware/mini2.nix;

    config = {
      gpu'.arch = "zen5";

      networking.hostName = "mini";

      services'.jellyfin.enable = true;
      services'.immich.enable = true;
      services'.home-assistant.enable = true;

      programs'.niri.enable = true;
      services'.desktop.displays = with import ./machines/displays.nix; [
        alien
      ];

      programs.steam.enable = true;
    };
  };
}
