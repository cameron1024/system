{
  nixConfig = {
    extra-substituters = [
      "https://zed.cachix.org"
      "https://cache.garnix.io"
      "https://install.determinate.systems"
    ];
    extra-trusted-public-keys = [
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixgl.url = "github:nix-community/nixGL";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    hypr-utils.url = "github:cameron1024/hypr-utils";
    hypr-utils.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    sherlock.url = "github:Skxxtz/sherlock";

    television.url = "github:alexpasmantier/television";

    zmk.url = "github:lilyinstarlight/zmk-nix";
    zmk.inputs.nixpkgs.follows = "nixpkgs";

    zed.url = "github:zed-industries/zed/nightly";
    # zed.url = "github:zed-industries/zed";

    hexecute.url = "github:ThatOtherAndrew/Hexecute";

    tracy.url = "github:tukanoidd/tracy.nix";
    tracy.inputs.nixpkgs.follows = "nixpkgs";

    nix-snapd.url = "github:nix-community/nix-snapd";
    nix-snapd.inputs.nixpkgs.follows = "nixpkgs";

    handy.url = "github:cameron1024/handy";
    handy.inputs.nixpkgs.follows = "nixpkgs";

    vicinae.url = "github:vicinaehq/vicinae";

    streamcontroller.url = "github:Daaboulex/streamcontroller-nix";
    streamcontroller.inputs.nixpkgs.follows = "nixpkgs";
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
    # Recursively wrap every script under `root` into a package. `.sh` files
    # become writeShellApplication, `.py` files become writePython3Bin, and
    # subdirectories become nested attrsets (e.g. scripts/foo/bar.sh ->
    # scripts.foo.bar). The shebang is stripped here so the source files stay
    # runnable on their own without their contents being otherwise altered.
    # An optional `<name>.nix` sidecar may provide `runtimeInputs` (added to
    # PATH) and/or `libraries` (Python imports).
    mkScripts = pkgs: root: let
      inherit (pkgs) lib;

      stripShebang = text: let
        lines = lib.splitString "\n" text;
      in
        if lines != [] && lib.hasPrefix "#!" (builtins.head lines)
        then lib.concatStringsSep "\n" (builtins.tail lines)
        else text;

      mkScript = dir: base: ext: let
        sidecar = dir + "/${base}.nix";
        meta =
          if builtins.pathExists sidecar
          then import sidecar {inherit pkgs;}
          else {};
        runtimeInputs = meta.runtimeInputs or [];
        libraries = meta.libraries or [];
        body = stripShebang (builtins.readFile (dir + "/${base}.${ext}"));
      in
        if ext == "sh"
        then
          pkgs.writeShellApplication {
            name = base;
            inherit runtimeInputs;
            text = body;
          }
        else let
          bin =
            pkgs.writers.writePython3Bin base {
              inherit libraries;
              flakeIgnore = ["E501"];
            }
            body;
          pyEnv = pkgs.python3.withPackages (ps: libraries ++ [ps.mypy]);
        in
          # Type-check with `mypy --strict` at build time, then expose the bin
          # (prefixing PATH with runtimeInputs when the sidecar asks for any).
          pkgs.runCommandLocal base {
            nativeBuildInputs = [pkgs.makeWrapper];
            meta.mainProgram = base;
          } ''
            cp ${dir + "/${base}.${ext}"} script.py
            ${pyEnv}/bin/mypy --strict --cache-dir="$TMPDIR/mypy" script.py

            makeWrapper ${bin}/bin/${base} $out/bin/${base} ${
              lib.optionalString (runtimeInputs != [])
              "--prefix PATH : ${lib.makeBinPath runtimeInputs}"
            }
          '';

      walk = dir:
        lib.pipe (builtins.readDir dir) [
          (lib.mapAttrsToList (name: type: let
            m = builtins.match "(.+)\\.(sh|py)" name;
          in
            if type == "directory"
            then {
              inherit name;
              value = walk (dir + "/${name}");
            }
            else if m == null
            then null
            else {
              name = builtins.head m;
              value = mkScript dir (builtins.head m) (builtins.elemAt m 1);
            }))
          (builtins.filter (x: x != null))
          builtins.listToAttrs
        ];
    in
      walk root;
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

    legacyPackages."x86_64-linux".scripts =
      mkScripts (import inputs.nixpkgs {system = "x86_64-linux";}) ./scripts;
    legacyPackages."aarch64-darwin".scripts =
      mkScripts (import inputs.nixpkgs {system = "aarch64-darwin";}) ./scripts;

    packages."x86_64-linux".vim = mkNixvim {system = "x86_64-linux";};
    packages."aarch64-linux".vim = mkNixvim {system = "aarch64-linux";};
    packages."aarch64-darwin".vim = mkNixvim {system = "aarch64-darwin";};

    packages."x86_64-linux".firmware = (mkKeyboard {system = "x86_64-linux";}).firmware;
    packages."x86_64-linux".keyboardFirmware = (mkKeyboard {system = "x86_64-linux";}).firmware;
    packages."x86_64-linux".keyboardFlash = (mkKeyboard {system = "x86_64-linux";}).flash;
    packages."x86_64-linux".keyboardUpdate = (mkKeyboard {system = "x86_64-linux";}).update;
  };
}
