{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    nixgl.url = "github:guibou/nixGL";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, nixgl }:

    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [ nixgl.overlay ];
      };

      buildSystem = { hardware }: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (import ./configuration.nix ./hardware/thinkpad.nix)
          (import ./home.nix)
          home-manager.nixosModules.home-manager
        ];
      };

      thinkpad = nixos-hardware.nixosModules.thinkpad;

    in

    {
      nixpkgs.config.allowUnfree = true;
      nixosConfigurations.nixos = buildSystem { hardware = thinkpad; };

    };

}
