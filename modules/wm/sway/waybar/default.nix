{ pkgs, lib, config, ... }:

let
  cfg = config.programs.customWaybar;
  colors = cfg.colors;
in
{ 
  options = with lib; {
    programs.customWaybar = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
      colors = mkOption {
        type = types.attrs;
      };
    };
  };


  config = lib.mkIf cfg.enable {
    home-manager.users.cameron = {
      home.packages = [
        pkgs.waybar
      ];

      /* xdg.configFile."waybar/config".source = ./config.json; */
      /* xdg.configFile."waybar/style.css".source = ./style.css; */
    };
  };

}
