{ pkgs, lib, config, ... }:

let
  cfg = config.programs.customWaybar;
  colors = cfg.colors;

  prePatch = ''
    sed -i -e 's/zext_workspace_handle_v1_activate(workspace_handle_);/const std::string command = "hyprctl dispatch workspace " + name_;\n\tsystem(command.c_str());/g' src/modules/wlr/workspace_manager.cpp
  '';
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
        (pkgs.waybar.overrideDerivation (oldAttrs: {
          inherit prePatch;
        }))
      ];

      xdg.configFile."waybar/config".source = ./config.json;
      xdg.configFile."waybar/style.css".source = ./style.css;
      xdg.configFile."waybar/mocha.css".source = ./mocha.css;
    };
  };

}
