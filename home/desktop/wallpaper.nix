{
  pkgs,
  lib,
  config,
  ...
}: let
  wallpaper = config.services'.desktop.wallpaper;
  setWallpaper = pkgs.writeShellApplication {
    name = "set-wallpaper.sh";
    runtimeInputs = with pkgs; [
      swww
      wallpaper
    ];
    text = ''
      
      ln -sf ${wallpaper} "$HOME/.wallpaper"
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
    services'.desktop.wallpaper = mkOption {
      type = types.package;
      default = (import ../../nixos/machines/wallpapers.nix).darkForest pkgs;
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
