{
  pkgs,
  lib,
  config,
  nixosConfig,
  inputs,
  ...
}:
with lib; {
  imports = [
    ./screenshot.nix
    ../hyprland/hardware.nix
    ../desktop

  ];

  options.programs'.niri = {
    extraConfig = mkOption {
      type = types.str;
      description = "Extra .kdl config to append to the generated config";
      default = "";
    };
  };

  config = mkIf (pkgs.stdenv.isLinux && (nixosConfig.programs'.niri.enable or false)) {
    services'.desktop.enable = true;
    home.packages = with pkgs; [
      wl-clipboard
      xwayland-satellite
      material-icons
      glib
      wayscriber
      playerctl
      # Toggle gaps + window corner radius by swapping the config.kdl symlink
      # between the two Nix-generated variants. niri auto-reloads on the change
      # (it canonicalizes the watched path), and we also nudge it for zero latency.
      (writeShellScriptBin "niri-toggle-gaps" ''
        set -u
        dir="''${XDG_CONFIG_HOME:-$HOME/.config}/niri"
        cfg="$dir/config.kdl"
        gaps="$(readlink -f "$dir/config-gaps.kdl")"
        current="$(readlink -f "$cfg" 2>/dev/null || true)"
        if [ "$current" = "$gaps" ]; then
          ln -sfn "$dir/config-no-gaps.kdl" "$cfg"
        else
          ln -sfn "$dir/config-gaps.kdl" "$cfg"
        fi
        niri msg action load-config-file >/dev/null 2>&1 || true
      '')
      # Live, ephemeral GUI monitor arrangement via wlr-output-management.
      # Drag-to-arrange, applies immediately, writes no config (reverts on
      # niri restart) - exactly what we want.
      wdisplays
    ];

    home.pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
    };
    

    # We generate two immutable config variants and let a toggle script (and the
    # activation script below) point ~/.config/niri/config.kdl at one of them.
    # config.kdl itself is intentionally NOT managed by home-manager so the
    # symlink target survives rebuilds; only the variants are regenerated.
    xdg.configFile = let
      formatDisplay = {
        name,
        resolution,
        position,
        refreshRate,
        scale,
        ...
      }:
      /*
      kdl
      */
      ''
        output "${name}" {
            mode "${toString resolution.width}x${toString resolution.height}@${toString refreshRate}"
            scale ${toString scale}
            transform "normal"
            position x=${toString position.x} y=${toString position.y}
        }
      '';
      displaysConfig = map formatDisplay nixosConfig.services'.desktop.displays or [];
      baseConfig =
        /*
        kdl
        */
        ''
          ${builtins.readFile ./config.kdl}
          ${lib.strings.concatMapStrings (x: x + "\n") displaysConfig}


          ${config.programs'.niri.extraConfig}
        '';
      # Flat variant: no gaps, square window corners, and no focus ring.
      # Instead of the ring, inactive windows are darkened. niri has no
      # "dark overlay" primitive, so we combine two things:
      #   1. Make the layout background opaque black (instead of transparent),
      #      so it hides the backdrop wallpaper behind windows.
      #   2. Lower inactive windows' opacity, so they blend toward that black
      #      background -- i.e. they look dimmed/darkened rather than
      #      see-through to the wallpaper.
      # Per monitor, the active window on each output stays fully opaque.
      noGapsConfig = builtins.replaceStrings
        [
          "gaps 24"
          "geometry-corner-radius 12"
          "background-color \"transparent\""
          "// Uncomment this line to disable the focus ring.\n        // off"
        ]
        [
          "gaps 0"
          "geometry-corner-radius 0"
          "background-color \"#000000\""
          "// Uncomment this line to disable the focus ring.\n        off"
        ]
        baseConfig
        +
        /*
        kdl
        */
        ''

          // no-gaps variant only: focus ring is disabled above; darken inactive
          // windows instead (they blend toward the opaque black background set
          // above). Lower the opacity for a stronger dim, raise it for subtler.
          // Use is-focused=false to dim all but the single globally-focused
          // window (ignores per-monitor active windows).
          window-rule {
              match is-active=false
              opacity 0.7
          }
        '';
    in {
      "niri/config-gaps.kdl".text = baseConfig;
      "niri/config-no-gaps.kdl".text = noGapsConfig;
    };

    # Default config.kdl to the gapped variant on first use (or if it goes
    # missing). Existing symlinks are left alone so the toggle state persists.
    home.activation.niriGapsDefault = lib.hm.dag.entryAfter ["writeBoundary"] ''
      cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl"
      if [ ! -e "$cfg" ]; then
        run ln -sfn "$(dirname "$cfg")/config-gaps.kdl" "$cfg"
      fi
    '';
  };
}
