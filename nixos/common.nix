{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.machine;
  linux = pkgs.linuxPackages_6_9;

in {

  options = with lib; {
    machine = {
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
    };
  };

  config =  {

    
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = cfg.boot;
    boot.kernelPackages = linux;

    networking.hostName = cfg.hostname;
    networking.networkmanager.enable = true;

    time.timeZone = "Europe/London";

    console.keyMap = "uk";

    users.users.cameron = {
      isNormalUser = true;
      description = "cameron";
      extraGroups = ["networkmanager" "wheel" "audio" "video" "sound"];
    };

    environment.systemPackages = with pkgs; [
      git
      vim
      firefox
      networkmanager
      jq
    ];

    nix = {
      package = pkgs.nixVersions.stable;

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
