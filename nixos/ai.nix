{
  pkgs,
  config,
  lib,
  ...
}:
with lib; {
  options = {
    services'.ai.enable = mkEnableOption "AI stuff";
  };
  config = mkIf config.services'.ai.enable {
    services.ollama.enable = true;
    services.ollama.host = "0.0.0.0";
    services.ollama.openFirewall = true;
    services.ollama.environmentVariables = {
      "OLLAMA_KEEP_ALIVE" = "2h";
      "OLLAMA_NUM_PARALLEL" = "5";
      "OLLAMA_NOHISTORY" = "true";
      "OLLAMA_MAX_LOADED_MODELS" = "2";
    };

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
