{
  programs.nixvim.plugins.trouble = {
    enable = true;
    lazyLoad.enable = true;
    lazyLoad.settings.cmd = ["Trouble"];
    lazyLoad.settings.keys = [
      {
        __unkeyed-1 = "<C-e>";
        __unkeyed-2 = "<cmd>Trouble diagnostics toggle<cr>";
      }
    ];
  };
}
