return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  version = "v3.1.0",
  lazy = true,
  cmd = "Trouble",
  opts = {},
  keys = {
    { "<C-e>", "<cmd>Trouble diagnostics toggle<cr>",          desc = "Toggle Diagnostics" },
    { "<C-s>", "<cmd>Trouble symbols toggle<cr>",              desc = "Toggle Symbol" },
    { "gr",    "<cmd>Trouble lsp_references toggle<cr>",       desc = "Toggle References" },
    { "gi",    "<cmd>Trouble lsp_implementations toggle<cr>",  desc = "Toggle Implementations" },
    { "gt",    "<cmd>Trouble lsp_type_definitions toggle<cr>", desc = "Toggle Type Definitions" },
  }
}
