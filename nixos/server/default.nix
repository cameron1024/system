{
  config,
  lib,
  ...
}: {
  imports = [
    ./adguard.nix
    ./dashboard.nix
    ./home-assistant
  ];
  options.services' = {
    immich.enable = lib.mkEnableOption "Enable Immich service";
    jellyfin.enable = lib.mkEnableOption "Enable Jellyfin service";
  };

  config = {
    services.jellyfin = lib.mkIf config.services'.jellyfin.enable {
      # port = 8096
      enable = true;
      openFirewall = true;
    };

    services.immich = lib.mkIf config.services'.immich.enable {
      enable = true;
      openFirewall = true;
      port = 2283;
      host = "0.0.0.0";
    };
  };
}
