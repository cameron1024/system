{
  programs.nixvim = {
    plugins.avante.enable = true;
    plugins.avante.settings = {
      provider = "ollama";
      providers.ollama = {
        endpoint = "http://mini:11112";
        model = "mistralai/devstral-small-2505";
      };
    };

    performance.combinePlugins.standalonePlugins = [
      "avante.nvim"
    ];
  };
}
