{
  pkgs,
  config,
  lib,
  ...
}:
with lib; {
  options = {
    services'.ai.enable = mkEnableOption "AI stuff";
    services'.ai.ollama.enable = mkOption {
      default = config.services'.ai.enable;
    };
  };
  config = mkIf config.services'.ai.enable {
    environment.systemPackages = with pkgs; [
      lmstudio
      jan
    ];

    # networking.firewall.allowedTCPPorts = [11112];
  };
}
