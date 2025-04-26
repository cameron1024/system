{
  programs.nixvim.keymaps = [
    {
      key = "<leader>q";
      action = "<cmd>x<cr>";
    }
    {
      key = "<leader>w";
      action = "<cmd>wa<cr>";
    }

    # move while in insert mode
    {
      key = "<C-h>";
      mode = "i";
      action = "<Left>";
    }
    {
      key = "<C-j>";
      mode = "i";
      action = "<Down>";
    }
    {
      key = "<C-k>";
      mode = "i";
      action = "<Up>";
    }
    {
      key = "<C-l>";
      mode = "i";
      action = "<Right>";
    }

    {
      key = "H";
      mode = ["n" "o" "x" "v"];
      action = "^";
    }
    {
      key = "L";
      mode = ["n" "o" "x" "v"];
      action = "g_";
    }

    # * stays on the same line
    {
      key = "*";
      action = "*N";
    }

    # keep selection when indenting
    {
      key = ">";
      mode = ["v"];
      action = ">gv";
    }
    {
      key = "<";
      mode = ["v"];
      action = "<gv";
    }

    {
      key = "<leader><tab>";
      action = "<C-^>";
    }
    {
      key = "<C-v>";
      action = "<cmd>vs<cr>";
    }
    {
      key = "<C-x>";
      action = "<cmd>sp<cr>";
    }
    {
      key = "<leader>v";
      action = "<C-v>";
    }
  ];
}
