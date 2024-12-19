return {
  "aznhe21/actions-preview.nvim",
  lazy = true,
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require 'actions-preview'.setup {
      highlight_command = {
        require("actions-preview.highlight").delta(),
      },
      telescope = vim.tbl_extend(
        "force",
        require("telescope.themes").get_ivy(),
        {
          make_value = nil,
          make_make_display = nil,
        }
      ),
    }
  end,
  keys = {
    { "<leader>a", function() require 'actions-preview'.code_actions() end, desc = "Code Actions" }
  }
}
