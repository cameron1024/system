{
  config,
  lib,
  ...
}: let
  hostname = config.networking.hostName;
in {
  config = lib.mkIf (hostname == "mini") {
    services.openssh.enable = true;
    services.openssh.openFirewall = true;
  };
}
