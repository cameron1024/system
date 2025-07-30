{
  plugins.trouble = {
    enable = true;
    lazyLoad.enable = true;
    lazyLoad.settings.cmd = ["Trouble"];
    lazyLoad.settings.keys = [
      {
        __unkeyed-1 = "<C-e>";
        __unkeyed-2 = "<cmd>Trouble diagnostics toggle<cr>";
      }
      {
        __unkeyed-1 = "<C-s>";
        __unkeyed-2 = "<cmd>Trouble symbols toggle<cr>";
      }
    ];

    settings.keys = {
      "<C-s>" = false;
      "<C-x>" = "jump_split";
    };
  };
}
