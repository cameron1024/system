{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.machine;
  linux = pkgs.linuxPackages_6_14;
in {
  imports = [
    ./hyprland
    ./dev/android.nix
    ./performance.nix
    ./greeter.nix
    ./games
    ./containers.nix
    ./postgres.nix
    ./ai.nix
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
    # fonts.packages = with pkgs; [
    #   nerdfonts
    #   fira
    #   monaspace
    # ];

    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      fira
      monaspace
    ];

    environment.systemPackages = with pkgs; [
      git
      curl
      vim
      firefox
      networkmanager
      jq
      linux.cpupower
      linux.perf
      ffmpeg
    ];
    # ++ (
    #   if (cfg.cpuArch != "znver5")
    #   then []
    #   else [intel-gpu-tools]
    # );

    nixpkgs.config.packageOverrides = lib.mkIf (cfg.cpuArch != "znver5") (pkgs: {
      intel-vaapi-driver = pkgs.intel-vaapi-driver.override {enableHybridCodec = true;};
    });

    hardware.graphics.enable = true;

    hardware.graphics.extraPackages = lib.mkIf (cfg.cpuArch != "znver5") (with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
      vpl-gpu-rt
      # intel-gpu-tools
    ]);

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
        system-features = lib.mkIf (cfg.cpuArch == "znver5") ["gccarch-znver5"];
      };
    };
  };
}
