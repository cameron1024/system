return {
  "emmanueltouzery/decisive.nvim",
  lazy = true,
  ft = "csv",
  opts = {},
  keys = {
    { '<leader>cca', ":lua require('decisive').align_csv({})<cr>" },
  }
}
