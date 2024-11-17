{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # v0.44.0
    # hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1&rev=0c7a7e2d569eeed9d6025f3eef4ea0690d90845d";

    # hyprland-plugins.url = "github:hyprwm/hyprland-plugins/v0.43.0";
    # hyprland-plugins.inputs.hyprland.follows = "hyprland";
    #
    # hyprspace.url = "github:KZDKM/Hyprspace";
    # hyprspace.inputs.hyprland.follows = "hyprland";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    ags.url = "github:Aylur/ags";
    ags.inputs.nixpkgs.follows = "nixpkgs";

    hypr-utils.url = "github:cameron1024/hypr-utils";
    hypr-utils.inputs.nixpkgs.follows = "nixpkgs";

    binsider.url = "github:orhun/binsider";
    binsider.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: let
    mkDevShell = {system}: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
      pkgs.mkShell {
        packages = [];
      };
  in {
    nixosConfigurations = import ./nixos {
      inherit inputs;
    };

    darwinConfigurations."DGQ204V94P" = inputs.nix-darwin.lib.darwinSystem rec {
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
