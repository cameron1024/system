return {
  "rcarriga/nvim-dap-ui",
  dependencies = {
    "mfussenegger/nvim-dap",
    "nvim-neotest/nvim-nio",
  },
  lazy = true,
  opts = {},
  keys = {
    { "<C-d><C-d>", function() require 'dapui'.toggle() end, desc = "Toggle Debug UI" },
  },
}
