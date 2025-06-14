{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.machine;
  linux = pkgs.linuxPackages_6_15;
in {
  imports = [
    # ./hyprland
    ./niri
    ./dev/android.nix
    ./performance.nix
    ./greeter.nix
    ./games
    ./containers.nix
    ./postgres.nix
    ./ai.nix
    ./gpu.nix
    ./virtualization.nix
    ./home-assistant
    ./ssh.nix
    ./server
  ];
  options = with lib; let
    colorOption = mkOption {
      type = types.str;
    };
  in {
    machine = {
      linux = mkOption {
        type = types.bool;
      };
      cpuArch = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      kernelParams = mkOption {
        type = types.listOf types.str;
        default = [];
      };
      user = {
        name = mkOption {
          type = types.str;
        };
        email = mkOption {
          type = types.str;
        };
      };

      extraFirmware = mkOption {
        default = null;
      };

      hostname = mkOption {
        type = types.str;
      };

      boot = mkOption {
        type = types.nullOr types.str;
        default = "/boot";
        description = "The path to the boot dir";
      };

      hardware = mkOption {
        type = types.path;
        description = "Path to the hardware-configuration.nix file";
      };

      wm = {
        hyprland.enable = mkEnableOption "Enable hyprland";
      };

      colorscheme.name = mkOption {
        type = types.str;
      };
      colorscheme.base00 = colorOption;
      colorscheme.base01 = colorOption;
      colorscheme.base02 = colorOption;
      colorscheme.base03 = colorOption;
      colorscheme.base04 = colorOption;
      colorscheme.base05 = colorOption;
      colorscheme.base06 = colorOption;
      colorscheme.base07 = colorOption;
      colorscheme.base08 = colorOption;
      colorscheme.base09 = colorOption;
      colorscheme.base0A = colorOption;
      colorscheme.base0B = colorOption;
      colorscheme.base0C = colorOption;
      colorscheme.base0D = colorOption;
      colorscheme.base0E = colorOption;
      colorscheme.base0F = colorOption;

      wallpapers = mkOption {
        type = types.list;
      };

      displays = mkOption {
        type = types.listOf {
          name = mkOption {
            type = types.str;
            description = "The name of the display";
          };
          resolution = mkOption {
            type = types.str;
            example = "1920x1080";
          };
          position = mkOption {
            type = types.str;
            example = "0x0";
          };
          refreshRate = mkOption {
            type = types.int;
            example = 60;
          };
          scale = mkOption {
            type = types.int;
            default = 1;
          };
          oled = mkOption {
            type = types.bool;
            default = false;
          };
        };
      };
    };
  };

  config = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = lib.mkIf (cfg.boot != null) cfg.boot;
    boot.loader.grub.memtest86.enable = true;
    boot.kernelPackages = linux;
    boot.kernelParams = cfg.kernelParams;

    hardware.enableAllFirmware = true;
    hardware.enableRedistributableFirmware = true;
    hardware.firmware =
      if cfg.extraFirmware != null
      then cfg.extraFirmware pkgs
      else [];

    networking.hostName = cfg.hostname;
    networking.networkmanager.enable = true;

    time.timeZone = "Europe/London";

    console.keyMap = "uk";

    users.users.cameron = {
      isNormalUser = true;
      description = "cameron";
      extraGroups = ["networkmanager" "wheel" "audio" "video" "sound" "input"];
    };

    fonts.enableDefaultPackages = true;
    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      fira
      monaspace
      noto-fonts
      noto-fonts-monochrome-emoji
    ];

    environment.systemPackages = with pkgs; [
      git
      curl
      vim
      networkmanager
      jq
      linux.cpupower
      linux.perf
      ffmpeg
      vulkan-tools
      clinfo
    ];
    # ++ (
    #   if (cfg.cpuArch != "znver5")
    #   then []
    #   else [intel-gpu-tools]
    # );

    nixpkgs.config.packageOverrides = lib.mkIf (cfg.cpuArch != "znver5") (pkgs: {
      intel-vaapi-driver = pkgs.intel-vaapi-driver.override {enableHybridCodec = true;};
    });

    hardware.ipu6.enable = true;
    hardware.ipu6.platform = "ipu6ep";

    environment.variables = {
      RUSTICL_ENABLE = "radeonsi";
      ROC_ENABLE_PRE_VEGA = "1";
    };

    hardware.graphics.enable = true;
    hardware.graphics.extraPackages = with pkgs; (
      []
      ++ (lib.optionals (cfg.cpuArch == "alderlake") [
        intel-media-driver
        intel-vaapi-driver
        libvdpau-va-gl
        vpl-gpu-rt
      ])
      ++ (lib.optionals (cfg.cpuArch == "znver5") [
        mesa
        libva
        libvdpau-va-gl
        vulkan-loader
        vulkan-validation-layers
        amdvlk
        mesa.opencl
      ])
    );
    # hardware.graphics.extraPackages = lib.mkIf (cfg.cpuArch != "znver5") (with pkgs; [
    #   intel-media-driver
    #   intel-vaapi-driver
    #   libvdpau-va-gl
    #   vpl-gpu-rt
    #   # intel-gpu-tools
    # ]);

    security.sudo.package = pkgs.sudo.override {withInsults = true;};

    nix = {
      package = pkgs.nixVersions.stable;
      registry.nixpkgs.flake = inputs.nixpkgs;

      extraOptions = ''
        experimental-features = nix-command flakes
      '';

      settings = {
        trusted-users = ["root" "@wheel"];
        substituters = ["https://hyprland.cachix.org"];
        trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
        system-features = let
          arch = cfg.cpuArch;
        in (
          []
          ++ (
            if arch == "znver5"
            then ["gccarch-znver5"]
            else []
          )
          ++ (
            if arch == "alderlake"
            then ["gccarch-alderlake"]
            else []
          )
        );
      };
    };
  };
}
