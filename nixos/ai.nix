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
      services.llama-cpp.enable = true;
      services.llama-cpp.openFirewall = true;
      services.llama-cpp.host = "0.0.0.0";
      services.llama-cpp.port = 13531;
      services.llama-cpp.modelsPreset = {
        "Qwen3-Coder-Next" = {
          hf-repo = "unsloth/Qwen3-Coder-Next-GGUF";
          hf-file = "Qwen3-Coder-Next-UD-Q4_K_XL.gguf";
          alias = "unsloth/Qwen3-Coder-Next";
          fit = "on";
          seed = "3407";
          temp = "1.0";
          top-p = "0.95";
          min-p = "0.01";
          top-k = "40";
          jinja = "on";
        };
      };
    # services.ollama = mkIf config.services'.ai.ollama.enable {
    #   enable = true;
    #   package = pkgs.ollama-rocm;
    #   host = "0.0.0.0";
    #   openFirewall = true;
    #   environmentVariables = {
    #     "OLLAMA_KEEP_ALIVE" = "2h";
    #     "OLLAMA_NUM_PARALLEL" = "5";
    #     "OLLAMA_NOHISTORY" = "true";
    #     "OLLAMA_MAX_LOADED_MODELS" = "2";
    #   };
    # };
    #
    # services.open-webui = {
    #   enable = true;
    #   host = "0.0.0.0";
    #   port = 11111;
    #   openFirewall = true;
    #   environment = {
    #     "OFFLINE_MODE" = "true";
    #   };
    # };

    environment.systemPackages = with pkgs; [
      (lmstudio.override {
        url = "https://installers.lmstudio.ai/linux/x64/0.3.21-3/LM-Studio-0.3.21-3-x64.AppImage";
        hash = "sha256-iErvVRfSS5BQNCSUM3YaCKO0ImblM+ijxPpFuZxmadI=";
      })
      jan
    ];

    systemd.user.services."lmstudio" = {
      enable = true;
      wantedBy = ["multi-user.target"];
      description = "LMStudio Service";
      script = ''
        ${pkgs.lmstudio}/bin/lms server start --port 11112 --log-level info
      '';
    };

    # networking.firewall.allowedTCPPorts = [11112];
  };
}
