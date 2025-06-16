{
  config,
  machine,
  lib,
  ...
}: let
  isServer = config.networking.hostName == "mini";
  isAmd = machine.cpuArch == "znver5";
in {
  config = {
    services.ollama.enable = true;
    services.ollama.host = "0.0.0.0";
    services.ollama.openFirewall = true;
    # services.ollama.acceleration = lib.mkIf isAmd "rocm";
    services.ollama.environmentVariables = {
      "OLLAMA_KEEP_ALIVE" = "2h";
      "OLLAMA_NUM_PARALLEL" = "5";
      "OLLAMA_NOHISTORY" = "true";
      "OLLAMA_MAX_LOADED_MODELS" = "2";
    };

    services.open-webui = lib.mkIf isServer {
      enable = true;
      host = "0.0.0.0";
      port = 11111;
      openFirewall = true;
      environment = {
        "OFFLINE_MODE" = "true";
      };
    };
  };
}
