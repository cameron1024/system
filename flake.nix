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
    homeConfigurations."cameron" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
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
          home.username = "cameron";
          home.homeDirectory = "/home/cameron";
          home.stateVersion = "25.11";

          programs.git.userName = "cameron";
          programs.git.userEmail = "cameron.studdstreet@gmail.com";
        }
      ];
    };

    nixosConfigurations = import ./nixos {
      inherit inputs;
    };

    darwinConfigurations."DTO-A032" = inputs.nix-darwin.lib.darwinSystem rec {
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
  };
}
