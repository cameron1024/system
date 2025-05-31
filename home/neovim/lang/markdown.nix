{
  programs.nixvim = {
    plugins.lsp.servers.marksman.enable = true;

    plugins.render-markdown = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.ft = ["markdown" "typst"];
      settings = {
        completions.lsp.enabled = true;
      };
      # settings = {
      #   preview.modes = ["n" "x"];
      #   preview.hybrid_modes = ["i" "r"];
      # };
    };

    # plugins.markview = {
    #   enable = true;
    #   lazyLoad.enable = true;
    #   lazyLoad.settings.ft = ["markdown" "typst"];
    #   settings = {
    #     preview.modes = ["n" "x"];
    #     preview.hybrid_modes = ["i" "r"];
    #   };
    # };
  };
}
