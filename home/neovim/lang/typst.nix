{
  programs.nixvim.plugins.typst-preview = {
    enable = true;
    lazyLoad.enable = true;
    lazyLoad.settings.ft = "typst";
  };
}
