{ pkgs, lib, config, ... }:
let
  cfg = config.programs.asdfNvim;
  colors = cfg.colors;
in
{
  options = with lib; {
    programs.asdfNvim = {
      enable = mkOption {
        type = types.bool;
      };
      colors = mkOption {
        type = types.attrs;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      package = pkgs.neovim-unwrapped;
      vimdiffAlias = true;
    };
  };
}
