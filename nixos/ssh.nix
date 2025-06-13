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

    services.static-web-server = {
      enable = true;
      listen = "0.0.0.0:8787";
      root = "/home/cameron/Public";
      configuration.general.directory-listing = true;
    };
    networking.firewall.allowedTCPPorts = [8787];
  };
}
