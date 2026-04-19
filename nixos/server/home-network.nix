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
              name = "admin";
              # generated via `htpasswd -bnBC 10 admin password`
              password = "admin:$2y$10$Y54ALyzkvMBG7yzXpJqMguYJu.zbc8PaMgCezlUPU1yQfngkMXrm6";
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
