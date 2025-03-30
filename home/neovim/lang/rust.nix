{
  programs.nixvim = {
    plugins.rustaceanvim = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.ft = "rust";
      settings.tools.test_executor = "neotest";
      settings.tools.enable_nextest = true;
      settings.tools.enable_clippy = true;
    };
  };
}
