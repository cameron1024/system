{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    naersk.url = "github:nix-community/naersk";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-23.05-darwin";

  };

  outputs = { self, nixpkgs, home-manager, nixpkgs-darwin, nix-darwin, naersk }:

    let

      macArgs = import ./platform/mac.nix {
        inherit naersk;   
        nixpkgs = nixpkgs-darwin;
      };

      linuxArgs = import ./platform/linux.nix {
        inherit naersk nixpkgs;
      };
      
      hardware = import ./hardware/thinkpad.nix;

      nixosSystem = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit hardware;
          naersk = linuxArgs.naersk;
          username = "cameron";
        };

        modules = [
          home-manager.nixosModules.home-manager

          ./configuration.nix
          ./modules/home
          ./tools

        ];
      };

      macosSystem = nix-darwin.lib.darwinSystem {

        specialArgs = {
          inherit hardware naersk;
          username = "cameron";
        };

        modules = [
          home-manager.darwinModules.home-manager
          {
            nixpkgs.hostPlatform = "aarch64-darwin";
            services.nix-daemon.enable = true;
          }

          # ./configuration.nix 
          ./modules/home
          # ./tools

        ];
      };


      switch = pkgs: pkgs.writeShellScriptBin "s" ''
        git add -A
        sudo nixos-rebuild switch --flake .
      '';
      switchOffline = pkgs: pkgs.writeShellScriptBin "so" ''
        git add -A
        sudo nixos-rebuild switch --flake . --offline
      '';
      reload = pkgs: pkgs.writeShellScriptBin "rl" ''
        hyprctl reload
        eww reload
      '';

    in

    {
      nixpkgs.config.allowUnfree = true;

      nixosConfigurations.nixos = nixosSystem;
      darwinConfigurations."Camerons-MacBook-Pro" = macosSystem;

      devShells."x86_64-linux".default = with linuxArgs; pkgs.mkShell {
        packages = [
          (switch pkgs)
          (switchOffline pkgs)
          (reload pkgs)
        ];
      };

      devShells."aarch64-darwin".default = with macArgs; pkgs.mkShell {
        packages = [
          (switch pkgs)
          (switchOffline pkgs)
          (reload pkgs)
        ];
      };

    };

}
