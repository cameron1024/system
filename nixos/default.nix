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
      system.stateVersion = "24.11";
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
      system.stateVersion = "24.11";
      gpu'.arch = "zen5";

      boot.binfmt.emulatedSystems = ["aarch64-linux"];

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

  pi = inputs.nixpkgs.lib.nixosSystem rec {
    system = "aarch64-linux";
    pkgs = import inputs.nixpkgs {inherit system;};
    modules = [
      # ./hardware/pi.nix
      inputs.nixos-hardware.nixosModules.raspberry-pi-4
      {
        system.stateVersion = "25.11";

        networking.hostName = "pi";

        users.users."nixos" = {
          isNormalUser = true;
          extraGroups = ["wheel" "networkmanager" "video"];
          initialHashedPassword = "";
        };

        users.users.root.initialHashedPassword = "";

        services.openssh.enable = true;
        services.openssh.openFirewall = true;
      }
    ];
  };
}
