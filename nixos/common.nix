{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.machine;
  linux = pkgs.linuxPackages_6_10;
in {
  imports = [./hyprland];
  options = with lib; let
    colorOption = mkOption {
      type = types.str;
    };
  in {
    machine = {
      user = {
        name = mkOption {
          type = types.str;
        };
        email = mkOption {
          type = types.str;
        };
      };

      hostname = mkOption {
        type = types.str;
      };

      boot = mkOption {
        type = types.str;
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
    boot.loader.efi.efiSysMountPoint = cfg.boot;
    boot.kernelPackages = linux;

    hardware.enableAllFirmware = true;
    hardware.enableRedistributableFirmware = true;

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
      nerdfonts
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
    ];

    nixpkgs.config.packageOverrides = pkgs: {
      intel-vaapi-driver = pkgs.intel-vaapi-driver.override {enableHybridCodec = true;};
    };

    hardware.graphics.enable = true;

    hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];

    nix = {
      package = pkgs.nixVersions.stable;
      # config.allowUnfree = true;

      extraOptions = ''
        experimental-features = nix-command flakes
      '';

      settings = {
        trusted-users = ["root" "@wheel"];
        substituters = ["https://hyprland.cachix.org"];
        trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
      };
    };
  };
}
