{
  pkgs,
  lib,
  config,
  ...
}: {
  services.postgresql = lib.mkIf config.services'.desktop.enable {
    enable = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all           trust
      host  all all 0.0.0.0/0 trust
      host  all all ::0/0     trust
    '';
  };
}
