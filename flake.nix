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

      hardware = import ./hardware/thinkpad.nix;

      nixosSystem = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          username = "cameron";
          inherit hardware;
        };
        modules = [
          home-manager.nixosModules.home-manager

          (import ./configuration.nix )
          ./modules/home

        ];
      };


      switch = pkgs.writeShellScriptBin "s" ''
        git add -A
        sudo nixos-rebuild switch --flake .
      '';
      switchOffline = pkgs.writeShellScriptBin "so" ''
        git add -A
        sudo nixos-rebuild switch --flake . --offline
      '';
      reload = pkgs.writeShellScriptBin "rl" ''
        hyprctl reload
        eww reload
      '';

    in

    {
      nixpkgs.config.allowUnfree = true;
      nixosConfigurations.nixos = nixosSystem;

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          switch
          switchOffline
          reload
        ];
      };

    };

}
