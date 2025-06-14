{
  config,
  lib,
  ...
}: let
  isServer = config.networking.hostName == "mini";
in {
  config = {
    services.ollama.enable = true;
    services.ollama.environmentVariables = {
      "OLLAMA_KEEP_ALIVE" = "2h";
      "OLLAMA_NUM_PARALLEL" = "5";
      "OLLAMA_NOHISTORY" = "true";
      "OLLAMA_MAX_LOADED_MODELS" = "2";
    };
    services.open-webui = lib.mkIf isServer {
      enable = true;
      port = 11111;
      openFirewall = true;
      environment = {
        "OFFLINE_MODE" = "true";
      };
    };
    networking.firewall.allowedTCPPorts = [11111];
  };
}
