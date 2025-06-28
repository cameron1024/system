{
  config,
  lib,
  pkgs,
  ...
}: {
  options = with lib.options; {
    services'.adguardhome = {
      enable = mkEnableOption "AdGuard Home";
    };
  };

  config = lib.mkIf config.services'.adguardhome.enable {
    services.adguardhome = {
      enable = true;
      openFirewall = true;
      mutableSettings = true;
      settings = {
        users = [
          {
            name = "cameron";
            # generated via `htpasswd -bnBC 10 cameron <password>`
            password = "$2y$10$/qsM6SVedU0E39CpaJjztuC8dnVfxqPiqGW3Vv/nTSup4FoRcHYv.";
          }
        ];
        dns.bind_hosts = ["0.0.0.0"];
        dns.bootstrap_dns = ["1.1.1.1"];
        dns.upstream_dns = ["1.1.1.1"];
      };
      port = 4909; # changing this seems to have no effect
      host = "0.0.0.0";
    };
    networking.firewall.allowedTCPPorts = [53];
    networking.firewall.allowedUDPPorts = [53];
  };
}
