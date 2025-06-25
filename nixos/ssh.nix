{
  config,
  lib,
  ...
}:
with lib; {
  options = {
    services'.openssh.enable = mkEnableOption "openssh";
  };
  config = lib.mkIf config.services'.openssh.enable {
    services.openssh.enable = true;
    services.openssh.openFirewall = true;
  };
}
