{inputs}: let
  mkSystem = {
    system,
    spec ? {},
    homeManager ? true,
    optimizations ? true,
    modules ? [],
    homeModules ? [],
    extraOverlays ? [],
  }: let
    overlays =
      (import ../overlays {
        inherit inputs optimizations;
        arch = spec.cpuArch or null;
      })
      ++ extraOverlays;

    machine = spec;

    specialArgs = {
      inherit inputs;
      inherit machine;
    };
  in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      inherit specialArgs;

      modules =
        modules
        ++ [
          ./common.nix
          {
            inherit machine;
            nixpkgs.overlays = overlays;
          }
        ]
        ++ (inputs.nixpkgs.lib.optionals homeManager [
          inputs.home-manager.nixosModules.default
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.cameron = import ../home;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.backupFileExtension = "backup";
          }
          {
            home-manager.users.cameron = {
              imports = homeModules;
            };
          }
        ]);
    };
in {
  framework = mkSystem {
    system = "x86_64-linux";
    spec = import ./machines/specs/thinkpad.nix {inherit inputs;};
    homeModules = [
      {
        home.stateVersion = "25.05";
      }
    ];
    modules = [
      ./hardware/framework.nix
      {
        system.stateVersion = "25.05";
        services'.standardMachine.enable = true;
        services'.standardMachine.zenKernel = true;
        gpu'.arch = "intel";

        boot.loader.efi.efiSysMountPoint = "/boot";

        networking.hostName = "framework";

        programs'.niri.enable = true;
        services'.desktop.isLaptop = true;
        services'.desktop.displays = with import ./machines/displays.nix; [
          frameworkBuiltin
          (rog
            // {
              name = "DP-10";
              refreshRate = 143.985;
            })
        ];
      }
    ];
  };
  fast = mkSystem {
    system = "x86_64-linux";
    spec = import ./machines/specs/thinkpad.nix {inherit inputs;};
    homeModules = [
      {
        home.stateVersion = "25.05";
      }
    ];
    modules = [
      ./hardware/fast.nix
      {
        system.stateVersion = "25.05";
        services'.standardMachine.enable = true;
        services'.standardMachine.zenKernel = true;
        gpu'.arch = "intel";

        boot.loader.efi.efiSysMountPoint = "/boot";

        networking.hostName = "fast";

        programs'.niri.enable = true;
        services'.desktop.isLaptop = true;
        services'.desktop.displays = with import ./machines/displays.nix; [
          (alien // { name = "HDMI-A-1"; refreshRate = 143.998; })
          # (rog
          #   // {
          #     name = "DP-10";
          #     refreshRate = 143.985;
          #   })
        ];
      }
    ];
  };
  thinkchad = mkSystem {
    system = "x86_64-linux";
    spec = import ./machines/specs/thinkpad.nix {inherit inputs;};
    homeModules = [
      {
        home.stateVersion = "24.11";
      }
    ];
    modules = [
      ./hardware/thinkpad.nix
      {
        system.stateVersion = "24.11";
        services'.standardMachine.enable = true;
        services'.standardMachine.zenKernel = true;
        gpu'.arch = "intel";

        boot.loader.efi.efiSysMountPoint = "/boot";

        networking.hostName = "thinkchad";

        programs'.niri.enable = true;
        services'.desktop.isLaptop = true;
        services'.desktop.displays = with import ./machines/displays.nix; [
          thinkpadBuiltin
          (rog
            // {
              name = "DP-6";
              refreshRate = 60;
            })
        ];

        programs.steam.enable = true;
      }
    ];
  };

  mini = mkSystem {
    system = "x86_64-linux";
    spec = import ./machines/specs/mini.nix {inherit inputs;};
    homeModules = [
      {
        home.stateVersion = "25.11";
        programs'.deployment-tools.enable = true;
      }
    ];
    modules = [
      ./hardware/mini2.nix
      {
        system.stateVersion = "24.11";
        services'.standardMachine.enable = true;
        services'.standardMachine.zenKernel = true;
        gpu'.arch = "zen5";

        boot.binfmt.emulatedSystems = ["aarch64-linux"];

        networking.hostName = "mini";

        services'.jellyfin.enable = true;
        services'.immich.enable = true;
        services'.home-assistant.enable = true;
        services'.ai.enable = true;
        services'.adguardhome.enable = true;
        services'.openssh.enable = true;

        programs.ssh.extraConfig = ''
          Host pi
            ForwardAgent yes
        '';
        programs'.niri.enable = true;
        services'.desktop.displays = with import ./machines/displays.nix; [
          alien
          rog
        ];

        programs.steam.enable = true;
      }
    ];
  };

  pi = mkSystem {
    system = "aarch64-linux";
    homeManager = false;
    extraOverlays = [
      # rpi kernel has some missing kernel modules - build fails without this
      (final: super: {
        makeModulesClosure = x: super.makeModulesClosure (x // {allowMissing = true;});
      })
    ];
    modules = [
      ./hardware/pi.nix
      inputs.nixos-hardware.nixosModules.raspberry-pi-4
      {
        system.stateVersion = "25.11";

        networking.hostName = "pi";
        networking.wireless.enable = false;

        users.users."cameron" = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "networkmanager"
            "video"
          ];
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII0+Mt9HeGZy7gpWXEn4WABPWO4jAWR3r24wlhW8bsIh cameron@mini"
          ];
        };

        users.users.root.initialHashedPassword = "";

        security.pam.sshAgentAuth.enable = true;
        security.pam.services.sshAgentAuth.enable = true;
        services'.openssh.enable = true;
        services'.adguardhome.enable = true;

        programs.neovim.enable = true;
      }
    ];
  };
}
