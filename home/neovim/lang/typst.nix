{
  programs.nixvim.plugins = {
    lsp.servers.tinymist.enable = true;
    typst-preview = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.ft = "typst";
    };
  };
}
