{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    naersk.url = "github:nix-community/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";

    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";

    hyprland-contrib.url = "github:hyprwm/contrib";
    hyprland-contrib.inputs.nixpkgs.follows = "nixpkgs";

    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    hyprland-plugins.inputs.hyprland.follows = "hyprland";

    hyprspace.url = "github:KZDKM/Hyprspace";
    hyprspace.inputs.hyprland.follows = "hyprland";

    hyprpicker.url = "github:hyprwm/hyprpicker";
    hyprpicker.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    catppuccinifier.url = "github:lighttigerXIV/catppuccinifier";
    catppuccinifier.inputs.nixpkgs.follows = "nixpkgs";

    wgsl-analyzer.url = "github:wgsl-analyzer/wgsl-analyzer";
    wgsl-analyzer.inputs.nixpkgs.follows = "nixpkgs";

    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = {
    nixpkgs,
    home-manager,
    nix-darwin,
    naersk,
    crane,
    ...
  } @ inputs: let
    overlays = [];

    macArgs = import ./platform/mac.nix {inherit inputs overlays;};
    linuxArgs = import ./platform/linux.nix {inherit inputs overlays;};
    allSpecialArgs = import ./configuration/args {inherit macArgs linuxArgs;};

    sharedModules = [
      ./configuration
    ];

    makeLinux = {args}:
      nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = args // {inherit inputs;};

        modules =
          sharedModules
          ++ [
            home-manager.nixosModules.home-manager
            inputs.catppuccin.nixosModules.catppuccin

            ./tools

            {
              nixpkgs.overlays = overlays;
              home-manager.extraSpecialArgs = specialArgs;
              home-manager.useGlobalPkgs = true;
              home-manager.users.${allSpecialArgs.shared.username} = {
                home.stateVersion = "22.05";
                imports = [
                  ./modules/home
                  inputs.catppuccin.homeManagerModules.catppuccin
                ];
              };
            }
          ];
      };

    miniSystem = makeLinux {args = allSpecialArgs.mini;};
    thinkpadSystem = makeLinux {args = allSpecialArgs.thinkpad;};
    thinkpad2System = makeLinux {args = allSpecialArgs.thinkpad2;};

    macosSystem = nix-darwin.lib.darwinSystem rec {
      specialArgs = allSpecialArgs.macos // {inherit inputs;};

      modules =
        sharedModules
        ++ [
          home-manager.darwinModules.home-manager
          {
            nixpkgs.overlays = overlays;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.useGlobalPkgs = true;
            home-manager.users.${allSpecialArgs.shared.username} = {
              home.stateVersion = "22.05";
              imports = [
                ./modules/home
                inputs.catppuccin.homeManagerModules.catppuccin
              ];
            };
          }
        ];
    };
  in {
    nixpkgs.config.allowUnfree = true;

    nixosConfigurations.mini = miniSystem;
    nixosConfigurations.thinkpad = thinkpadSystem;
    nixosConfigurations.thinkpad2 = thinkpad2System;

    darwinConfigurations."DGQ204V94P" = macosSystem;

    homeConfigurations."cameron" = home-manager.lib.homeManagerConfiguration {
      extraSpecialArgs = allSpecialArgs.server // {inherit inputs;};
      pkgs = linuxArgs.pkgs;

      modules = [
        {home.stateVersion = "23.11";}
        ./modules/home
      ];
    };

    devShells."x86_64-linux".default = with linuxArgs;
      pkgs.mkShell {
        packages = [
          (pkgs.writeShellScriptBin "s" ''
            git add -A
            eval $(device-manager switch)
          '')
        ];
      };

    devShells."aarch64-darwin".default = with macArgs;
      pkgs.mkShell {
        packages = [
          (pkgs.writeShellScriptBin "s" ''
            git add -A
            export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1
            nix run nix-darwin --extra-experimental-features flakes --extra-experimental-features nix-command --impure -- switch --flake .
          '')
        ];
      };
  };
}
