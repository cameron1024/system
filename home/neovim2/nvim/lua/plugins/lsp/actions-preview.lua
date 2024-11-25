return {
  "aznhe21/actions-preview.nvim",
  lazy = true,
  config = function()
    require 'actions-preview'.setup {
      highlight_command = {
        require("actions-preview.highlight").delta(),
      },
    }
  end,
  keys = {
    { "<leader>a", function() require 'actions-preview'.code_actions() end, desc = "Code Actions" }
  }
}
