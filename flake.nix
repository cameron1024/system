{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    nixgl.url = "github:guibou/nixGL";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, nixgl, neovim-nightly-overlay }:

    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [ 
          nixgl.overlay 
          neovim-nightly-overlay.overlay 
        ];
      };

      buildSystem = { hardware }: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (import ./configuration.nix ./hardware/thinkpad.nix)
          ./modules/home
          home-manager.nixosModules.home-manager

        ];
      };

      thinkpad = nixos-hardware.nixosModules.thinkpad;

      switch = pkgs.writeShellScriptBin "s" ''
        git add -A
        sudo nixos-rebuild switch --flake .
      '';
      update = pkgs.writeShellScriptBin "u" ''
        git add -A
        sudo nixos-rebuild switch --flake .
      '';

    in

    {
      nixpkgs.config.allowUnfree = true;
      nixosConfigurations.nixos = buildSystem { hardware = thinkpad; };

      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = [
          switch 
          update 
        ];
      };

    };

}
