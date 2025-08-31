let
  enable = true;
  lazyLoad = {
    enable = true;
    settings.event = "InsertEnter";
  };
in {
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

  plugins.todo-comments.enable = true;
  plugins.todo-comments.lazyLoad.enable = true;
  plugins.todo-comments.lazyLoad.settings.event = "BufReadPost";

  plugins.marks.enable = true;
  plugins.marks.cyclic = true;
  plugins.marks.defaultMappings = true;

  plugins.undotree.enable = true;

  plugins.colorizer.enable = true;
  plugins.colorizer.lazyLoad.enable = true;
  plugins.colorizer.lazyLoad.settings.cmd = "ColorizerToggle";

  plugins.img-clip.enable = true;
  plugins.img-clip.lazyLoad.settings.cmd = "PasteImage";

  keymaps = [
    {
      key = "<leader>m";
      action.__raw = "function() Snacks.picker.marks() end";
    }
    {
      key = "<C-u>";
      action = "<cmd>UndotreeToggle<cr>";
    }
  ];


}
