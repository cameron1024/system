{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, hyprland }:

    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };

      buildSystem = { hardware }: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (import ./configuration.nix ./hardware/thinkpad.nix)
          ./modules/home
          home-manager.nixosModules.home-manager
          hyprland.nixosModules.default
        ];
      };

      thinkpad = nixos-hardware.nixosModules.thinkpad;

    in

    {
      nixpkgs.config.allowUnfree = true;
      nixosConfigurations.nixos = buildSystem { hardware = thinkpad; };

    };

}
