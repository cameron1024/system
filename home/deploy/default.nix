{
  lib,
  config,
  pkgs,
  ...
}:
with lib; {
  options = {
    programs'.deployment-tools.enable = mkEnableOption "NixOS deployment tools";
  };

  config = mkIf config.programs'.deployment-tools.enable {
    home.packages = with pkgs; [
      nixos-generators
      caligula
    ];
  };
}
