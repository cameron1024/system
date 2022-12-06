{ pkgs, lib, config, ... }:
let
  cfg = config.programs.wofi;
  colors = cfg.colors;
in
{

  options = with lib; {
    programs.wofi = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
      colors = mkOption {
        type = types.attrs;
      };

    };
  };

  config = {
    home-manager.users.cameron = {
      home.packages = [
        pkgs.wofi
      ];
      xdg.configFile."wofi/config".text = with colors; ''
        width=300
        term=kitty
      '';

      xdg.configFile."wofi/style.css".text = with colors; ''
        @define-color base00 ${base00};
        @define-color base01 ${base01};
        @define-color base02 ${base02};
        @define-color base03 ${base03};
        @define-color base04 ${base04};
        @define-color base06 ${base05};
        @define-color base06 ${base06};
        @define-color base07 ${base07};
        @define-color base08 ${base08};
        @define-color base09 ${base09};
        @define-color base0A ${base0A};
        @define-color base0B ${base0B};
        @define-color base0C ${base0C};
        @define-color base0D ${base0D};
        @define-color base0E ${base0E};
        @define-color base0F ${base0F};

        window {
          opacity: 0.9;
          border:  0px;
          border-radius: 10px;
          font-family: "FiraCode Nerd Font";
          font-size: 18px;
        }

        #input {
        	border-radius: 10px 10px 0px 0px;
          border:  0px;
          padding: 10px;
          margin: 0px;
          font-size: 28px;
        	color: @base0B;
        	background-color: @base03;
        }

        #inner-box {
        	margin: 0px;
        	color: @base06;
        	background-color: @base00;
        }

        #outer-box {
        	margin: 0px;
        	background-color: @base00;
          border-radius: 10px;
        }

        #selected {
        	background-color: @base0D;
        }

        #entry {
        	padding: 0px;
          margin: 0px;
        	background-color: @base00;
        }

        #scroll {
        	margin: 5px;
        	background-color: @base00;
        }

        #text {
        	margin: 0px;
        	padding: 2px 2px 2px 10px;
        }
      '';
    };
  };

}
