{ pkgs, lib, config, ... }:
let
  cfg = config.programs.rofi;
in
{

  options = with lib; {
    programs.rofi = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
    };
  };

  config = {
    home-manager.users.cameron = {
      home.packages = [
        pkgs.rofi-wayland
      ];

      xdg.configFile."".source = ./config.rasi;
      home.file.".local/share/rofi/themes/catppuccin-mocha.rasi".source = ./theme.rasi;
    };
  };

}
