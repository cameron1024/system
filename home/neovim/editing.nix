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

    plugins.marks.enable = true;
    plugins.marks.cyclic = true;
    plugins.marks.defaultMappings = true;
    keymaps = [
      {
        key = "<leader>m";
        action.__raw = "function() Snacks.picker.marks() end";
      }
    ];
  };
}
