{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager }:

    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };

      buildSystem = { hardware }: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          username = "cameron";
        };
        modules = [
          home-manager.nixosModules.home-manager

          (import ./configuration.nix ./hardware/thinkpad.nix)
          ./modules/home

        ];
      };

      thinkpad = nixos-hardware.nixosModules.thinkpad;

      switch = pkgs.writeShellScriptBin "s" ''
        git add -A
        sudo nixos-rebuild switch --flake .
      '';
      switchOffline = pkgs.writeShellScriptBin "so" ''
        git add -A
        sudo nixos-rebuild switch --flake . --offline
      '';

    in

    {
      nixpkgs.config.allowUnfree = true;
      nixosConfigurations.nixos = buildSystem { hardware = thinkpad; };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          switch
                switchOffline
        ];
      };

    };

}
