{
  config,
  lib,
  ...
}: let
  isServer = config.networking.hostName == "mini";
in {
  config = lib.mkIf isServer {
    services.ollama.enable = true;
    services.ollama.environmentVariables = {
      "OLLAMA_KEEP_ALIVE" = "2h";
      "OLLAMA_NUM_PARALLEL" = "5";
      "OLLAMA_NOHISTORY" = "true";
      "OLLAMA_MAX_LOADED_MODELS" = "2";
    };
    services.open-webui.enable = true;
    services.open-webui.port = 11111;
    services.open-webui.openFirewall = true;
    services.open-webui.environment = {
      "OFFLINE_MODE" = "true";
    };
  };
}
