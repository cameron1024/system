{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services'.nix-cache.enable {
    services.nix-serve = {
      enable = true;
      secretKeyFile = "/var/secrets/cache-private-key.pem";
    };

    # services.nginx = {
    #   enable = true;
    #   recommendedProxySettings = true;
    #   virtualHosts.cache = {
    #     locations."/".proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
    #   };
    # };

    networking.firewall.allowedTCPPorts = [
      config.services.nginx.defaultHTTPListenPort
    ];
  };
}
