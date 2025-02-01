return {
  "m4xshen/hardtime.nvim",
  lazy = true,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
  },
  cmd = "Hardtime",
  -- event = "BufReadPost",
  config = function()
    require 'hardtime'.setup {
      disabled_filetypes = {
        "help",
        "qf",
        "netrw",
        "neo-tree",
        "lazy",
        "mason",
        "oil",
      },
    }
  end
}
