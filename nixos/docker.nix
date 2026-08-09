{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.services'.docker.enable = mkEnableOption "docker";

  config = mkIf config.services'.docker.enable {
    virtualisation.docker.enable = true;

    # Allow using docker without sudo
    users.users.cameron.extraGroups = ["docker"];

    environment.systemPackages = with pkgs; [
      docker-compose
    ];
  };
}
