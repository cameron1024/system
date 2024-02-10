{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    naersk.url = "github:nix-community/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";

    hyprland-contrib.url = "github:hyprwm/contrib";
    hyprland-contrib.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    anyrun.url = "github:Kirottu/anyrun";
    anyrun.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = { nixpkgs, home-manager, nix-darwin, naersk, mac-app-util, anyrun, ... } @ inputs:

    let
      macArgs = import ./platform/mac.nix inputs;
      linuxArgs = import ./platform/linux.nix inputs;
      allSpecialArgs = import ./configuration/args { inherit macArgs linuxArgs; };

      sharedModules = [
        ./configuration
        ./modules/home
        ./tools
      ];

      makeLinux =  { args }: nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = args // { inherit inputs; };

        modules = sharedModules ++ [
          home-manager.nixosModules.home-manager
          { home-manager.extraSpecialArgs = specialArgs; }
        ];
      };

      miniSystem = makeLinux { args = allSpecialArgs.mini; };
      thinkpadSystem = makeLinux { args = allSpecialArgs.thinkpad; };

      macosSystem = nix-darwin.lib.darwinSystem rec {
        specialArgs = allSpecialArgs.macos // { inherit inputs; };

        modules = sharedModules ++ [
          home-manager.darwinModules.home-manager
          { home-manager.extraSpecialArgs = specialArgs; }
          
          mac-app-util.darwinModules.default
        ];
      };

    in
    {
      nixpkgs.config.allowUnfree = true;

      nixosConfigurations.mini = miniSystem;
      nixosConfigurations.thinkpad = thinkpadSystem;

      darwinConfigurations."DGQ204V94P" = macosSystem;

      homeConfigurations."cameron" = home-manager.lib.homeManagerConfiguration {
        extraSpecialArgs = allSpecialArgs.server // { inherit inputs; };
        pkgs = linuxArgs.pkgs;

        modules = [
          { home.stateVersion = "23.11"; }
          ./modules/home
        ];

      };

      devShells."x86_64-linux".default = with linuxArgs; pkgs.mkShell {
        packages = [
          (pkgs.writeShellScriptBin "s" ''
            git add -A
            eval $(device-manager switch)
          '')
        ];
      };

      devShells."aarch64-darwin".default = with macArgs; pkgs.mkShell {
        packages = [
          (pkgs.writeShellScriptBin "s" ''
            git add -A
            nix run nix-darwin --extra-experimental-features flakes --extra-experimental-features nix-command -- switch --flake .
          '')
        ];
      };

    };

}
