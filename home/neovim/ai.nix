{pkgs,...}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [magenta]; 
    extraConfigLua = ''
      require 'magenta'.setup {
        profiles = {
          name = "lm-studio",
          provider = "ollama",
          host = "http://mini:11112",
          model = "devstral-small-2505",
        },
      }
    '';
    # plugins.avante.enable = true;
    # plugins.avante.settings = {
    #   provider = "ollama";
    #   providers.ollama = {
    #     endpoint = "http://mini:11112";
    #     model = "mistralai/devstral-small-2505";
    #   };
    # };
    #
    # performance.combinePlugins.standalonePlugins = [
    #   "avante.nvim"
    # ];
  };
}
