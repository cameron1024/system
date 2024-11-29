return {
  "3rd/diagram.nvim",
  lazy = true,
  ft = { "markdown", },
  dependencies = {
    "3rd/image.nvim",
  },
  config = function()
    require 'diagram'.setup {

      integrations = {
        require 'diagram.integrations.markdown',
      },
      renderer_options = {
        mermaid = {
          theme = "forest",
        },
      }
    }
  end,
}
