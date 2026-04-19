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
              # generated via `htpasswd -bnBC 10 cameron password`
              password = "cameron:$2y$10$2MTbXN.RWKSeHT4NJngIIeFmdgMPQFbgBD/QtotpkJU15atDquX7m";
            }
          ];
          dns.bind_hosts = ["0.0.0.0"];
          dns.bootstrap_dns = ["1.1.1.1"];
          dns.upstream_dns = ["1.1.1.1"];

          querylog.enabled = false;
          statistics.enabled = true;
        };
        port = 4909;
        host = "0.0.0.0";
      };

      # Use local AdGuard Home for DNS resolution, bypassing the router.
      # 1.1.1.1 is a fallback in case AdGuard Home is down.
      networking.nameservers = ["127.0.0.1" "1.1.1.1"];

      networking.firewall.allowedTCPPorts = [53];
      networking.firewall.allowedUDPPorts = [53];
    })

    (lib.mkIf config.services'.ntopng.enable {
      services.ntopng = {
        enable = true;
        httpPort = 3000;

        # By default, monitors all interfaces. Once port mirroring is set up
        # on a managed switch, change this to the specific interface receiving
        # mirrored traffic, e.g. ["enp2s0"]
        interfaces = ["any"];

        extraConfig = ''
          # Limit memory usage — generous for a home network
          --max-num-hosts=1024
          --max-num-flows=65536
        '';
      };

      networking.firewall.allowedTCPPorts = [3000];

      # After first boot, configure the following in the ntopng web UI
      # (http://<host>:3000, default credentials admin/admin):
      #
      # Settings > Preferences > Data Retention:
      #   - Set to 30 days
      #
      # Settings > Preferences > Timeseries:
      #   - Host Timeseries: "Light" (default, records traffic volume per host)
      #   - L7 Application Timeseries: "None" (avoids recording which apps/services each device uses)
      #
      # Do NOT enable:
      #   - Flow dump to ClickHouse (this would persistently log individual connections)
    })
  ];
}
