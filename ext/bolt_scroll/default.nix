# NixOS module for bolt_scroll: smooth (hi-res) wheel scrolling for HID++
# mice on a Logitech Bolt receiver, which mainline hid-logitech-dj doesn't
# drive. See src/main.rs for the details.
#
# Requires hi-res mode to be enabled on the mouse, e.g. via Solaar:
#   solaar config "MX Master 3S" hires-smooth-resolution true
# Without it, scrolling is `multiplier` times too slow.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.services'.bolt-scroll;

  package = pkgs.callPackage ./build.nix {
    craneLib = inputs.crane.mkLib pkgs;
  };
in {
  options.services'.bolt-scroll = {
    enable = lib.mkEnableOption "hi-res scroll rescaling for Logitech Bolt receivers";

    multiplier = lib.mkOption {
      type = lib.types.ints.positive;
      default = 15;
      description = ''
        The mouse's HID++ hi-res wheel multiplier (wheel ticks per notch).
        Shown as "Multiplier" under HIRES WHEEL in `solaar show`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # HID++ hi-res mode is volatile: the mouse drops it whenever it
    # reconnects (power cycle, deep sleep). Solaar re-applies saved settings
    # on reconnect, but only while it's running.
    programs.solaar.userService.enable = lib.mkDefault true;

    # Loads uinput and makes /dev/uinput writable by the `uinput` group.
    hardware.uinput.enable = true;

    systemd.services.bolt-scroll = {
      description = "Hi-res scroll rescaling for Logitech Bolt receivers";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${lib.getExe package} --multiplier ${toString cfg.multiplier}";
        Restart = "always";
        RestartSec = 1;

        # Needs /dev/input/event* and /dev/uinput, nothing else.
        DynamicUser = true;
        SupplementaryGroups = ["input" "uinput"];
        DeviceAllow = ["char-input rw" "/dev/uinput rw"];
        DevicePolicy = "closed";
        PrivateNetwork = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = ["AF_UNIX"];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        SystemCallArchitectures = "native";
        # Every pointer event goes through this process.
        Nice = -10;
      };
    };
  };
}
