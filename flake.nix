{
  description = "my dots";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, home-manager }: 

  let
    tunables = import ./tunables.nix;
    device = import ./device.nix { nixpkgs = pkgs; };
    colors = import ./color.nix { colorscheme = tunables.colorscheme; };
  in
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
	home-manager.nixosModules.home-manager
	({...}: {
          home-manager.users.cameron = import ./home.nix { pkgs = nixpkgs; inherit config; };
	})
      ];
    };

  };

}
