{
  config,
  lib,
  ...
}: {
  options.services' = {
    reverse-proxy.enable = lib.mkEnableOption "Caddy reverse proxy for .lan service domains";
  };

  config = lib.mkIf config.services'.reverse-proxy.enable {
    # Routes LAN-only service domains (resolved to this host by the router's
    # dnsmasq, see ext/router-config/deploy.sh) to the right local port based
    # on the Host header. The "http://" prefix keeps Caddy on plain HTTP —
    # .lan isn't a real TLD, so no certificates can be issued for it.
    services.caddy = {
      enable = true;
      virtualHosts = {
        "http://home.lan".extraConfig = ''
          reverse_proxy 127.0.0.1:8123
        '';
        "http://media.lan".extraConfig = ''
          reverse_proxy 127.0.0.1:8096
        '';
      };
    };

    networking.firewall.allowedTCPPorts = [80];
  };
}
