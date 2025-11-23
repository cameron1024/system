{
  extraConfigLua = ''
    if vim.g.neovide then
        vim.keymap.set(
          { "n", "v" },
          "<C-+>",
          ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1<CR>"
        )
        vim.keymap.set(
          { "n", "v" },
          "<C-->",
          ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1<CR>"
        )
        vim.keymap.set(
          { "n" , "v" },
          "<C-0>",
          ":lua vim.g.neovide_scale_factor = 1<CR>"
        )
    end
  '';
  keymaps = [
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
      key = "]q";
      action = ":cnext<cr>zz";
    }
    {
      key = "[q";
      action = ":cprev<cr>zz";
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
    {
      key = "<C-q>";
      action.__raw = ''
        function()
          local qf_exists = false
          for _, win in pairs(vim.fn.getwininfo()) do
            if win["quickfix"] == 1 then
              qf_exists = true
            end
          end
          if qf_exists == true then
            vim.cmd "cclose" return
          end
          if not vim.tbl_isempty(vim.fn.getqflist()) then
            vim.cmd "copen"
          end
        end
      '';
    }
    {
      key = "<C-d>";
      action = "<cmd>nohl<cr>";
    }
  ];
}
