{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";

    hyprland-contrib.url = "github:hyprwm/contrib";
    hyprland-contrib.inputs.nixpkgs.follows = "nixpkgs";

    hyprland-plugins.url = "github:hyprwm/hyprland-plugins/v0.41.2";
    hyprland-plugins.inputs.nixpkgs.follows = "nixpkgs";

    hyprspace.url = "github:KZDKM/Hyprspace";

    hyprpicker.url = "github:hyprwm/hyprpicker";

    hy3.url = "github:outfoxxed/hy3";

    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    ags.url = "github:Aylur/ags";
    ags.inputs.nixpkgs.follows = "nixpkgs";

    hypr-utils.url = "github:cameron1024/hypr-utils";
    hypr-utils.inputs.nixpkgs.follows = "nixpkgs";
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
