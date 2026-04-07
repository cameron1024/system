{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services'.nix-cache.enable {
    services.harmonia = {
      enable = true;
      signKeyPaths = [config.services'.nix-cache.secretKeyFile];
      settings.bind = "0.0.0.0:5000";
    };

    networking.firewall.allowedTCPPorts = [5000];
  };
}
