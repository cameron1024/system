{inputs}: let
  mkSystem = {
    system,
    spec,
    hardware,
    config ? {},
  }: let
    overlays = [
      (import inputs.rust-overlay)
      (import ../overlays/gcc_optimizations.nix {
        inherit inputs;
        arch = machine.cpuArch;
        packageList = [
          # "neovim"
        ];
      })
      (import ../overlays/rust_optimizations.nix {
        inherit inputs;
        arch = machine.cpuArch;
        packageList = [
          "rust-analyzer"
          "starship"
          "ripgrep"
          "eza"
          "nushell"
          "fish"
          "television"
        ];
      })
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
        hardware
        {
          inherit machine;

          system.stateVersion = "24.11";
          nixpkgs = {
            config.allowUnfree = true;
            config.rocmSupport = machine.cpuArch == "znver5";
            overlays = overlays;
          };

          nix.registry.nixpkgs.flake = inputs.nixpkgs;

          home-manager.useGlobalPkgs = true;
          home-manager.users.cameron = import ../home;
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.backupFileExtension = "backup";
        }
        config
      ];
    };
in {
  thinkchad = mkSystem {
    system = "x86_64-linux";
    spec = import ./machines/specs/thinkpad.nix {inherit inputs;};
    hardware = ./hardware/thinkpad.nix;

    config = {
      gpu'.arch = "intel";

      programs'.niri.enable = true;

      services'.desktop.enable = true; 
      services'.desktop.displays = with import ./machines/displays.nix; [
        thinkpadBuiltin  
      ];
    };
  };

  mini = mkSystem {
    system = "x86_64-linux";
    spec = import ./machines/specs/mini.nix {inherit inputs;};
    hardware = ./hardware/mini2.nix;

    config = {
      gpu'.arch = "zen5";

      services'.jellyfin.enable = true;
      services'.immich.enable = true;
      services'.home-assistant.enable = true;

      services'.desktop.enable = true; 
      services'.desktop.displays = with import ./machines/displays.nix; [
        alien  
      ];

      programs'.niri.enable = true;


    };
  };
}
