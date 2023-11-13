{ isDarwin, username, lib, ... }:

with lib; {
  nixpkgs.config.allowUnfree = true;

  nixpkgs.hostPlatform = mkIf isDarwin "aarch64-darwin";
  services.nix-daemon.enable = mkIf isDarwin true;

  users.users.${username} = mkIf isDarwin {
    description = username;
    home = "/Users/${username}";
  };
}
