return {
  "folke/noice.nvim",
  event = "VeryLazy",
  enabled = vim.g.started_by_firenvim == nil,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
    "smjonas/inc-rename.nvim",
  },
  opts = {
    messages = {
      enabled = true,
      view_search = "virtualtext",
    },
    notify = {
      enabled = false,
    },
    lsp = {
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        -- ["cmp.entry.get_documentation"] = true,
      },
    },
    presets = {
      bottom_search = true,
      lsp_doc_border = true,
      inc_rename = true,
    },
  },
  config = function(_, opts)
    require 'inc_rename'.setup()
    require 'noice'.setup(opts)
  end,
  keys = {
    { "<leader><esc>", "<cmd>NoiceDismiss<cr>", desc = "Dismiss Popups" },
    { "<leader>r",     ":IncRename ",           desc = "Rename" },
  }
}
