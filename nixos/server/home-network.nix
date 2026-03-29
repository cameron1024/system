{
  config,
  lib,
  ...
}: {
  options.services' = {
    adguardhome.enable = lib.mkEnableOption "AdGuard Home";
    ntopng.enable = lib.mkEnableOption "ntopng network monitoring";
  };

  config = lib.mkMerge [
    (lib.mkIf config.services'.adguardhome.enable {
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

          querylog.enabled = false;
          statistics.enabled = false;
        };
        port = 4909;
        host = "0.0.0.0";
      };

      networking.nameservers = ["127.0.0.1" "1.1.1.1"];

      networking.firewall.allowedTCPPorts = [53];
      networking.firewall.allowedUDPPorts = [53];
    })

    (lib.mkIf config.services'.ntopng.enable {
      services.ntopng = {
        enable = true;
        httpPort = 3000;

        interfaces = ["any"];

        extraConfig = ''
          # Limit memory usage — generous for a home network
          --max-num-hosts=1024
          --max-num-flows=65536
        '';
      };

      networking.firewall.allowedTCPPorts = [3000];
    })
  ];
}
