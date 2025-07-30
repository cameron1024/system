{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixgl.url = "github:nix-community/nixGL";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    rustaceanvim.url = "github:mrcjkb/rustaceanvim";
    rustaceanvim.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";

    astal.url = "github:Aylur/astal";
    astal.inputs.nixpkgs.follows = "nixpkgs";

    ags.url = "github:aylur/ags";
    ags.inputs.nixpkgs.follows = "nixpkgs";

    quickshell.url = "github:quickshell-mirror/quickshell";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";

    hypr-utils.url = "github:cameron1024/hypr-utils";
    hypr-utils.inputs.nixpkgs.follows = "nixpkgs";

    lla.url = "github:chaqchase/lla";
    lla.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim";

    sherlock.url = "github:Skxxtz/sherlock";

    television.url = "github:alexpasmantier/television";
  };

  outputs = inputs: let
    mkNixvim = {system}: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = import ./overlays {inherit inputs;};
        config.allowUnfree = true;
      };
      nixvim = inputs.nixvim.legacyPackages.${system};
      nixvimModule = {
        inherit pkgs;
        extraSpecialArgs = {inherit inputs;};
        module = {
          imports = [./home/neovim/module.nix];
          # colorschemes.everforest.enable = true;
          # colorscheme = "everforest";
        };
      };
    in
      nixvim.makeNixvimWithModule nixvimModule;
    mkDevShell = {system}: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
      pkgs.mkShell {
        packages =
          if system == "aarch64-darwin"
          then [
            (pkgs.writeShellScriptBin "s" ''
              cd $(git rev-parse --show-toplevel)

              git add -A
              sudo nix run nix-darwin \
                --extra-experimental-features flakes \
                --extra-experimental-features nix-command \
                -- switch --flake .
            '')
          ]
          else [
            (pkgs.writeShellScriptBin "s" ''
              cd $(git rev-parse --show-toplevel)

              git add -A
              sudo nixos-rebuild switch --flake .#$(hostname)
            '')
          ];
      };
  in {
    homeConfigurations =
      builtins.listToAttrs
      (
        map
        ({
          username,
          system,
        }: {
          name = username;
          value = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = import ./overlays {
                inherit inputs;
                optimizations = false;
              };
            };
            extraSpecialArgs = {
              inherit inputs;
              machine = {};
            };
            modules = [
              ./home
              {
                home.username = username;
                home.stateVersion = "25.11";
              }
            ];
          };
        })
        [
          {
            username = "cameron";
            system = "x86_64-linux";
          }
          {
            username = "ubuntu";
            system = "aarch64-linux";
          }
        ]
      );

    nixosConfigurations = import ./nixos {
      inherit inputs;
    };

    darwinConfigurations."DTO-A032" = inputs.nix-darwin.lib.darwinSystem rec {
      pkgs = import inputs.nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
        overlays = import ./overlays {inherit inputs;};
      };
      specialArgs = {
        inherit inputs;
        machine = import ./nixos/machines/specs/macbook.nix;
      };
      modules = [
        inputs.home-manager.darwinModules.home-manager
        ./mac
        {
          home-manager.users.cameron = import ./home;
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.backupFileExtension = "backup";
        }
      ];
    };

    devShells."x86_64-linux".default = mkDevShell {system = "x86_64-linux";};
    devShells."aarch64-darwin".default = mkDevShell {system = "aarch64-darwin";};

    packages."x86_64-linux".vim = mkNixvim {system = "x86_64-linux";};
    packages."aarch64-linux".vim = mkNixvim {system = "aarch64-linux";};
    packages."aarch64-darwin".vim = mkNixvim {system = "aarch64-darwin";};
  };
}
