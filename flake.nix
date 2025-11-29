{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixgl.url = "github:nix-community/nixGL";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    hypr-utils.url = "github:cameron1024/hypr-utils";
    hypr-utils.inputs.nixpkgs.follows = "nixpkgs";

    lla.url = "github:chaqchase/lla";
    lla.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    sherlock.url = "github:Skxxtz/sherlock";

    television.url = "github:alexpasmantier/television";

    zmk.url = "github:lilyinstarlight/zmk-nix";
    zmk.inputs.nixpkgs.follows = "nixpkgs";

    kani-repo.url = "git+https://github.com/model-checking/kani?ref=main&rev=96f7e59a8c8058f3edbdcc4d52940e376d54ff09&submodules=1";
    kani-repo.flake = false;

    kani-tarball.url = "https://github.com/model-checking/kani/releases/download/kani-0.64.0/kani-0.64.0-x86_64-unknown-linux-gnu.tar.gz";
    kani-tarball.flake = false;

    zed.url = "github:zed-industries/zed";
    zed.inputs.nixpkgs.follows = "nixpkgs";

    hexecute.url = "github:ThatOtherAndrew/Hexecute";

    noctalia.url = "github:noctalia-dev/noctalia-shell";
    noctalia.inputs.nixpkgs.follows = "nixpkgs";

    niri.url = "github:yalter/niri/v25.11";
  };

  outputs = inputs: let
    mkKeyboard = {system}: import ./firmware/keyboard {inherit system inputs;};
    mkNixvim = {system}: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = import ./overlays {inherit inputs;};
        config.allowUnfree = true;
      };
    in
      inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
        inherit pkgs;
        extraSpecialArgs = {inherit inputs;};
        module.imports = [./home/neovim/module.nix];
      };
    mkDevShell = {system}: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
      pkgs.mkShell {
        packages =
          if system == "aarch64-darwin"
          then [
            (pkgs.writeShellScriptBin
              "s"
              ''
                cd $(git rev-parse --show-toplevel)

                git add -A
                sudo nix run nix-darwin \
                  --extra-experimental-features flakes \
                  --extra-experimental-features nix-command \
                  -- switch --flake .
              '')
          ]
          else [
            (pkgs.writeShellScriptBin "s" ''
              cd $(git rev-parse --show-toplevel)

              git add -A
              sudo nixos-rebuild switch --flake .#$(hostname)
            '')
          ];
      };
  in {
    homeConfigurations =
      builtins.listToAttrs
      (
        map
        ({
          username,
          system,
        }: {
          name = username;
          value = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = import ./overlays {
                inherit inputs;
                optimizations = false;
              };
            };
            extraSpecialArgs = {
              inherit inputs;
              machine = {};
            };
            modules = [
              ./home
              {
                home.username = username;
                home.stateVersion = "25.11";
              }
            ];
          };
        })
        [
          {
            username = "cameron";
            system = "x86_64-linux";
          }
          {
            username = "ubuntu";
            system = "aarch64-linux";
          }
        ]
      );

    nixosConfigurations = import ./nixos {
      inherit inputs;
    };

    devShells."x86_64-linux".default = mkDevShell {system = "x86_64-linux";};
    devShells."aarch64-darwin".default = mkDevShell {system = "aarch64-darwin";};

    packages."x86_64-linux".vim = mkNixvim {system = "x86_64-linux";};
    packages."aarch64-linux".vim = mkNixvim {system = "aarch64-linux";};
    packages."aarch64-darwin".vim = mkNixvim {system = "aarch64-darwin";};

    packages."x86_64-linux".firmware = (mkKeyboard {system = "x86_64-linux";}).firmware;
    packages."x86_64-linux".keyboardFirmware = (mkKeyboard {system = "x86_64-linux";}).firmware;
    packages."x86_64-linux".keyboardFlash = (mkKeyboard {system = "x86_64-linux";}).flash;
    packages."x86_64-linux".keyboardUpdate = (mkKeyboard {system = "x86_64-linux";}).update;
  };
}
