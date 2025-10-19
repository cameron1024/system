{
  pkgs,
  lib,
  config,
  ...
}: let
  wallpapers = config.services'.desktop.wallpapers;
  setWallpaper = pkgs.writeShellApplication {
    name = "set-wallpaper.sh";
    runtimeInputs = [
      pkgs.swww
      wallpapers
    ];
    text = ''
      CURRENT=$(readlink -f "$HOME/.wallpaper")
      WALLPAPER=$(find ${wallpapers}/* ! -path "$CURRENT" | shuf -n 1)
      >&2 echo "wallpaper: $WALLPAPER" 

      ln -sf "$WALLPAPER" "$HOME/.wallpaper"
      swww img "$HOME/.wallpaper" \
        --resize crop \
        --transition-fps 120 \
        --transition-pos top-left \
        --transition-duration 0.4 \
        --transition-type grow
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
      swww
      setWallpaper
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
