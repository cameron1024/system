{
  programs.nixvim.plugins.lean = {
    enable = true;
    lazyLoad.enable = true;
    lazyLoad.settings.ft = "lean";
    settings.mappings = true;
  };
}
