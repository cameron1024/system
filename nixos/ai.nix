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

    environment.systemPackages = with pkgs; [
      lmstudio
      jan
    ];

    # networking.firewall.allowedTCPPorts = [11112];
  };
}
