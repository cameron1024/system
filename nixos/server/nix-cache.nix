{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services'.nix-cache.enable {
    services.nix-serve = {
      enable = true;
      port = 5000;
      secretKeyFile = config.services'.nix-cache.secretKeyFile;
    };

    networking.firewall.allowedTCPPorts = [
      config.services.nix-serve.port
    ];
  };
}
