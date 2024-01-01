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

  outputs = { self, nixpkgs, home-manager, nix-darwin, naersk, ... } @ inputs:

    let
      macArgs = import ./platform/mac.nix {
        inherit naersk nixpkgs;
      };

      linuxArgs = import ./platform/linux.nix {
        inherit naersk nixpkgs; 
      };

      args = import ./configuration/args.nix { inherit macArgs linuxArgs; };

      makeLinux =  { hyprland, hardware, boot }: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit hardware hyprland boot inputs;
          naersk = linuxArgs.naersk;
          username = "cameron";
          isDarwin = false;
        };
        modules = [
          home-manager.nixosModules.home-manager

          ./configuration.nix
          ./modules/home
          ./modules/tools
          ./tools
        ];
      };

      miniSystem = makeLinux {
        hardware = import ./configuration/hardware/mini.nix;
        hyprland = true;
        boot = "/boot";
      };

      thinkpadSystem = makeLinux {
        hardware = import ./configuration/hardware/thinkpad.nix;
        hyprland = true;
        boot = "/boot/efi";
      };

      macosSystem = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit naersk;
          username = "cameron";
          isDarwin = true;
        };

        modules = [
          home-manager.darwinModules.home-manager

          ./configuration.nix 
          ./modules/home
          ./modules/tools
          ./tools

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
            git add -A
            eval $(device-manager switch)
          '')
        ];
      };

    };

}
