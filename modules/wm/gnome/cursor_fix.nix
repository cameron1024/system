# Module to set a default cursor theme
# taken from https://github.com/NixOS/nixpkgs/issues/22652
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.environment.defaultCursor;

  indexThemeText = theme: generators.toINI {} {"icon theme" = {Inherits = "${theme}";};};

  mkDefaultCursorFile = theme:
    pkgs.writeTextDir
    "share/icons/default/index.theme"
    "${indexThemeText theme}";

  defaultCursorPkg = mkDefaultCursorFile cfg.theme;
in {
  options = {
    environment.defaultCursor = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to set a default cursor theme for graphical environments.
        '';
      };

      theme = mkOption {
        type = types.str;
        default = "";
        example = "Adwaita";
        description = "The name of the defualt cursor theme.";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      defaultCursorPkg
    ];
  };
}
