{
  programs.nixvim.plugins = {
    # typst-conceal.enable = true;
    lsp.servers.tinymist.enable = true;
    typst-preview = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.ft = "typst";
    };
  };
}
