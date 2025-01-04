{pkgs, ...}: {
  services.postgresql = {
    enable = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all           trust
      host  all all 0.0.0.0/0 trust
      host  all all ::0/0     trust
    '';
  };
}
