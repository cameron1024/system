return {
  "smjonas/inc-rename.nvim",
  lazy = true,
  opts = {},
  keys = {
    { "<leader>r", function() return ":IncRename " .. vim.fn.expand "<cword>" end, expr = true },
  }
}
