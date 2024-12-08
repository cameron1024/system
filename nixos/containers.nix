{
  virtualisation.docker.enable = true;
  users.users."cameron".extraGroups = ["docker"];
  # virtualisation.containers.enable = true;
  # virtualisation.podman = {
  #   enable = true;
  #   dockerCompat = true;
  #   defaultNetwork.settings.dns_enabled = true;
  # };
}
