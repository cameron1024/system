return {
  "m4xshen/hardtime.nvim",
  dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
  lazy = true,
  opts = {},
  cmd = { "Hardtime" },
  config = function()
    vim.cmd("Hardtime", "disable")
  end
}
