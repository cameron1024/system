let
  enable = true;
  lazyLoad = { enable = true; settings.event = "InsertEnter"; };
in{
  programs.nixvim = {
    plugins.nvim-autopairs = {
      inherit enable lazyLoad;
    };

    plugins.nvim-surround = {
      inherit enable lazyLoad;
    };
  };
}
