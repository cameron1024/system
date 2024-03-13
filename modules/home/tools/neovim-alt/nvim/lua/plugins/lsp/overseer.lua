return {
  "stevearc/overseer.nvim",
  dependencies = {
    "akinsho/toggleterm.nvim",
  },
  event = "VeryLazy",
  keys = {
    { "<C-d>", "<cmd>OverseerToggle<cr>", desc = "Toggle Overseer" },
    { "<leader>d", "<cmd>OverseerRun<cr>", desc = "Toggle Overseer" },
  },
  opts = {
    strategy = {
      "toggleterm",
    },
  },
}
