{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  wallpapers = config.services'.desktop.wallpapers;

  # Applies whatever wallpaper is currently pointed at by ~/.wallpaper to all
  # outputs. awww/swww's `img` only paints outputs that exist at call time, so
  # this is also what we run when a new monitor is hotplugged.
  applyWallpaper = pkgs.writeShellApplication {
    name = "apply-wallpaper.sh";
    runtimeInputs = [
      pkgs.awww
    ];
    text = ''
      [ -e "$HOME/.wallpaper" ] || exit 0
      awww img "$HOME/.wallpaper" \
        --resize crop \
        --transition-fps 120 \
        --transition-pos top-left \
        --transition-duration 0.4 \
        --transition-type grow
    '';
  };

  setWallpaper = pkgs.writeShellApplication {
    name = "set-wallpaper.sh";
    runtimeInputs = [
      applyWallpaper
      wallpapers
    ];
    text = ''
      CURRENT=$(readlink -f "$HOME/.wallpaper")
      WALLPAPER=$(find ${wallpapers}/* ! -path "$CURRENT" | shuf -n 1)
      >&2 echo "wallpaper: $WALLPAPER" 

      ln -sf "$WALLPAPER" "$HOME/.wallpaper"
      apply-wallpaper.sh
    '';
  };

  # Watches DRM hotplug events (monitor connect/disconnect) and re-applies the
  # current wallpaper so freshly connected monitors get a background without
  # having to re-run set-wallpaper.sh.
  wallpaperHotplug = pkgs.writeShellApplication {
    name = "wallpaper-hotplug.sh";
    runtimeInputs = [
      pkgs.systemd
      applyWallpaper
    ];
    text = ''
      udevadm monitor --udev --subsystem-match=drm | while read -r _; do
        # Coalesce the burst of events a single hotplug produces.
        while read -r -t 1 _; do :; done
        # Give the compositor a moment to create the new output.
        sleep 1
        apply-wallpaper.sh || true
      done
    '';
  };
in {
  options = with lib; {
    services'.desktop.wallpapers = mkOption {
      type = types.package;
      default = pkgs.wallpapers.all;
    };
  };

  config = lib.mkIf config.services'.desktop.enable {
    home.packages = with pkgs; [
      awww
      applyWallpaper
      setWallpaper
      # wallpaper-hotplug.sh is launched from niri's spawn-at-startup so it
      # inherits the same session env (WAYLAND_DISPLAY) that awww needs to
      # reach its daemon.
      wallpaperHotplug
    ];

    systemd.user.services."set-wallpaper" = {
      Unit = {
        Description = "Set wallpaper";
        After = ["multi-user.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = ''
          ${setWallpaper}
        '';
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
