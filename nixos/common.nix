{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.machine;
in {
  imports = [
    ./ai.nix
    ./desktop
    ./gpu.nix
    ./greeter.nix
    ./postgres.nix
    ./server
    ./ssh.nix
    ./webcam.nix
    ./standard.nix
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
      server = mkOption {
        type = types.bool;
        default = false;
      };
      cpuArch = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
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
    time.timeZone = "Europe/London";

    console.keyMap = "uk";

    # environment.systemPackages = with pkgs; [
    #   git
    #   curl
    #   vim
    #   networkmanager
    #   jq
    #   linux.cpupower
    #   linux.perf
    # ];
    # ++ (
    #   if (cfg.cpuArch != "znver5")
    #   then []
    #   else [intel-gpu-tools]
    # );

    security.sudo.package = pkgs.sudo.override {withInsults = true;};

    nixpkgs.config.allowUnfree = true;
    nix = {
      package = pkgs.nixVersions.stable;
      registry.nixpkgs.flake = inputs.nixpkgs;

      extraOptions = ''
        experimental-features = nix-command flakes
      '';

      settings = {
        trusted-users = ["root" "@wheel" "cameron"];
        substituters = ["https://hyprland.cachix.org"];
        trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
        system-features =
          []
          ++ (lib.optionals (cfg.cpuArch == "znver5") ["gccarch-znver5"])
          ++ (lib.optionals (cfg.cpuArch == "alderlake") ["gccarch-alderlake"]);
      };
    };
  };
}
