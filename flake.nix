{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";

    hyprland-contrib.url = "github:hyprwm/contrib";
    hyprland-contrib.inputs.nixpkgs.follows = "nixpkgs";

    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    hyprland-plugins.inputs.hyprland.follows = "hyprland";

    hyprspace.url = "github:KZDKM/Hyprspace";
    hyprspace.inputs.hyprland.follows = "hyprland";

    hyprpicker.url = "github:hyprwm/hyprpicker";
    hyprpicker.inputs.nixpkgs.follows = "nixpkgs";

    hy3.url = "github:outfoxxed/hy3";
    # or "github:outfoxxed/hy3" to follow the development branch.
    # (you may encounter issues if you dont do the same for hyprland)
    hy3.inputs.hyprland.follows = "hyprland";

    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: {
    nixosConfigurations = import ./nixos {
      inherit inputs;
    };

    devShells."x86_64-linux".default = let
      pkgs = import inputs.nixpkgs {system = "x86_64-linux";};
    in
      pkgs.mkShell {
        packages = [];
      };
  };
}
