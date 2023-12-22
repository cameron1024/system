{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    naersk.url = "github:nix-community/naersk";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, naersk }:

    let
      macArgs = import ./platform/mac.nix {
        inherit naersk nixpkgs;
      };

      linuxArgs = import ./platform/linux.nix {
        inherit naersk nixpkgs;
      };

      makeLinux =  { hyprland, hardware, boot }: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit hardware hyprland boot;
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
        hardware = import ./hardware/mini.nix;
        hyprland = true;
        boot = "/boot";
      };

      thinkpadSystem = makeLinux {
        hardware = import ./hardware/thinkpad.nix;
        hyprland = false;
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
          (pkgs.writeShellScriptBin "st" ''
            git add -A
            sudo nixos-rebuild switch --flake .#thinkpad
          '')
          (pkgs.writeShellScriptBin "sm" ''
            git add -A
            sudo nixos-rebuild switch --flake .#mini
          '')
        ];
      };

      devShells."aarch64-darwin".default = with macArgs; pkgs.mkShell {
        packages = [
          (pkgs.writeShellScriptBin "s" ''
            git add -A
            nix run nix-darwin -- switch --flake .
          '')
        ];
      };

    };

}
