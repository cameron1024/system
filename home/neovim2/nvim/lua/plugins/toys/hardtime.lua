return {
  "m4xshen/hardtime.nvim",
  lazy = true,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
  },
  cmd = "Hardtime",
  opts = {
    disabled_filetypes = { "qf", "netrw", "neo-tree", "lazy", "mason", "oil" },
  },
}
