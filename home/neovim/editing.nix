let
  enable = true;
  lazyLoad = {
    enable = true;
    settings.event = "InsertEnter";
  };
in {
  programs.nixvim = {
    plugins.auto-save = {
      inherit enable;
      lazyLoad.enable = true;
      lazyLoad.settings.event = "BufReadPost";
      settings.debounce_delay = 10;
    };
    plugins.nvim-autopairs = {
      inherit enable lazyLoad;
    };

    plugins.nvim-surround = {
      inherit enable lazyLoad;
    };
  };
}
