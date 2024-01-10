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

  };

  outputs = { nixpkgs, home-manager, nix-darwin, naersk, ... } @ inputs:

    let
      macArgs = import ./platform/mac.nix { inherit naersk nixpkgs; };
      linuxArgs = import ./platform/linux.nix { inherit naersk nixpkgs; };
      allSpecialArgs = import ./configuration/args { inherit macArgs linuxArgs; };

      sharedModules = [
        ./configuration
        ./modules/home
        ./modules/tools
        ./tools
      ];

      makeLinux =  { specialArgs }: nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = allSpecialArgs // { inherit inputs; };

        modules = sharedModules ++ [
          home-manager.nixosModules.home-manager
          { home-manager.extraSpecialArgs = specialArgs; }
        ];
      };

      miniSystem = makeLinux { specialArgs = allSpecialArgs.mini; };
      thinkpadSystem = makeLinux { specialArgs = allSpecialArgs.thinkpad; };

      macosSystem = nix-darwin.lib.darwinSystem rec {
        specialArgs = allSpecialArgs.macos // { inherit inputs; };

        modules = sharedModules ++ [
          home-manager.darwinModules.home-manager
          { home-manager.extraSpecialArgs = specialArgs; }
        ];
      };

    in
    {
      nixpkgs.config.allowUnfree = true;

      nixosConfigurations.mini = miniSystem;
      nixosConfigurations.thinkpad = thinkpadSystem;
      darwinConfigurations."DGQ204V94P" = macosSystem;

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
            nix run nix-darwin --extra-experimental-features flakes --extra-experimental-features nix-command -- switch --flake .
          '')
        ];
      };

    };

}
