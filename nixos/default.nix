{inputs}: let
  mkSystem = {
    system,
    spec ? {},
    hardware,
    config ? {},
    homeManager ? true,
    optimizations ? true,
  }: let
    overlays = import ../overlays {
      inherit inputs optimizations;
      arch = spec.cpuArch or null;
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
        ++ (inputs.nixpkgs.lib.optionals homeManager [
          inputs.home-manager.nixosModules.default
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.cameron = import ../home;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.backupFileExtension = "backup";
          }
        ]);
    };
in {
  thinkchad = mkSystem {
    system = "x86_64-linux";
    spec = import ./machines/specs/thinkpad.nix {inherit inputs;};
    hardware = ./hardware/thinkpad.nix;

    config = {
      system.stateVersion = "24.11";
      services'.standardMachine.enable = true;
      gpu'.arch = "intel";

      boot.loader.efi.efiSysMountPoint = "/boot";

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
      services'.standardMachine.enable = true;
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

  pi = mkSystem {
    system = "aarch64-linux";
    hardware = inputs.nixos-hardware.nixosModules.raspberry-pi-4;
    homeManager = false;
    config = {lib, ...}: {
      system.stateVersion = "25.11";

      networking.hostName = "pi";
      networking.wireless.enable = false;

      users.users."cameron" = {
        isNormalUser = true;
        extraGroups = ["wheel" "networkmanager" "video"];
        initialPassword = "password";
        initialHashedPassword = lib.mkForce null;
      };

      users.users.root.initialHashedPassword = "";

      services'.openssh.enable = true;
      services'.adguardhome.enable = true;
    };
  };
}
