{
  programs.nixvim = {
    # vim.g.* = ...;
    globals = {
      mapleader = " ";
      maplocalleader = "  ";
    };

    # vim.opt.* = ...;
    opts = {
      timeoutlen = 600;
      cmdheight = 0;
      tabstop = 2;

      number = true;
      relativenumber = true;
      hidden = true;
    };

    keymaps = [
      {
        key = "<leader>q";
        action = "<cmd>x<cr>";
      }
      {
        key = "<leader>w";
        action = "<cmd>wa<cr>";
      }
    ];
  };
}
