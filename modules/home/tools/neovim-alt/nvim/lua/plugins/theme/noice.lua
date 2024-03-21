return {
  "folke/noice.nvim",
  event = "VeryLazy",
  enabled = vim.g.started_by_firenvim == nil,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  opts = {
    messages = {
      enabled = false,
      view_search = "virtualtext",
    },
    lsp = {
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
    },
    presets = {
      bottom_search = true,
      lsp_doc_border = true,
    },
  },
}
