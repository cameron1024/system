# Kiosk-style Moonlight game-streaming session for a machine plugged into
# the living-room TV.
#
# moonlight-qt runs inside gamescope's embedded (DRM) mode as a dedicated,
# unprivileged `game-stream` user, auto-started at boot by greetd. gamescope
# owns the display directly (no desktop underneath), which is what enables
# HDR and VRR passthrough. greetd respawns the session whenever it exits, so
# quitting/crashing Moonlight just returns to the connection screen.
#
# The `game-stream` account has no password and no SSH keys: the auto-started
# kiosk session is the only way into it, and it holds no privileges beyond
# the seat devices logind grants to the active session.
{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.services'.moonlight-kiosk;

  session = pkgs.writeShellScript "moonlight-kiosk-session" ''
    # Session output is otherwise discarded; tag it in the journal so crashes
    # are debuggable (journalctl -t moonlight-kiosk).
    exec > >(${pkgs.systemd}/bin/systemd-cat -t moonlight-kiosk) 2>&1

    # Prefer moonlight's Vulkan renderer (required for HDR output).
    export PREFER_VULKAN=1
    # Qt's native Wayland backend aborts under gamescope's minimal compositor;
    # run moonlight through Xwayland instead.
    export QT_QPA_PLATFORM=xcb
    export SDL_VIDEODRIVER=x11

    exec ${pkgs.gamescope}/bin/gamescope \
      -W ${toString cfg.output.width} \
      -H ${toString cfg.output.height} \
      -r ${toString cfg.output.refreshRate} \
      --hdr-enabled \
      --adaptive-sync \
      --fullscreen \
      -- ${pkgs.moonlight-qt}/bin/moonlight
  '';
in {
  options.services'.moonlight-kiosk = {
    enable = mkEnableOption "Moonlight game-streaming kiosk session";

    output = {
      width = mkOption {
        type = types.ints.positive;
        default = 3840;
      };
      height = mkOption {
        type = types.ints.positive;
        default = 2160;
      };
      refreshRate = mkOption {
        type = types.ints.positive;
        default = 120;
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.services'.tuigreet.enable;
        message = "moonlight-kiosk and tuigreet both own the greetd default session; enable only one per machine.";
      }
    ];

    users.users.game-stream = {
      isNormalUser = true;
      description = "Moonlight kiosk (unprivileged)";
      # Seat device access mostly comes from logind for the active session;
      # these groups are a fallback for direct evdev/DRM access.
      extraGroups = ["video" "render" "input"];
    };

    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${session}";
        user = "game-stream";
      };
    };

    # Audio out over the DP->HDMI link. mini has no desktop config, so the
    # kiosk brings its own pipewire.
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    # Prefer the HDMI/DP audio path (-> TV -> eARC -> soundbar) over the
    # machine's internal USB speaker ("POROSVOC"), which wireplumber would
    # otherwise pick as the default sink.
    services.pipewire.wireplumber.extraConfig."60-moonlight-kiosk-prefer-hdmi" = {
      "monitor.alsa.rules" = [
        {
          matches = [{"node.name" = "~alsa_output.*hdmi.*";}];
          actions.update-props = {
            "priority.session" = 2000;
            "priority.driver" = 2000;
          };
        }
      ];
      # Output at full line level (like a set-top box); pipewire's default of
      # 0.4 makes the TV/soundbar very quiet. Volume is controlled downstream
      # by the TV/soundbar remote.
      "wireplumber.settings" = {
        "device.routes.default-sink-volume" = 1.0;
      };
    };

    # Bluetooth for game controllers. The kiosk session's logind seat grants
    # game-stream access to the controller's input devices once paired.
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;

    # udev rules for game controllers (Xbox/PlayStation/8BitDo/...)
    services.udev.packages = [pkgs.game-devices-udev-rules];
  };
}
