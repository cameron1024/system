return {
  "stevearc/overseer.nvim",
  dependencies = {
    "akinsho/toggleterm.nvim",
  },
  lazy = true,
  keys = {
    { "<C-d>",     "<cmd>OverseerToggle<cr>", desc = "Toggle Overseer" },
    { "<leader>d", "<cmd>OverseerRun<cr>",    desc = "Overseer Run" },
  },
  opts = {
    strategy = {
      "toggleterm",
    },
  },
}
