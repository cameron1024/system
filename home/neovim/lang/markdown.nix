{
  programs.nixvim = {
    filetype.extension."mdx" = "markdown";
    plugins.lsp.servers.marksman.enable = true;
    # plugins.lsp.servers.markdown_oxide.enable = true;
    # plugins.lsp.servers.markdown_oxide.settings.root_markers = [
    #   ".git"
    #   ".obsidian"
    #   ".moxide.toml"
    #   "book.toml"
    # ];

    plugins.render-markdown = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.ft = ["markdown" "typst"];
      settings = {
        completions.lsp.enabled = true;
        completions.blink.enabled = true;
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
