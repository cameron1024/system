return {
  "catppuccin/nvim",
  dependencies = {
    "stevearc/aerial.nvim",
  },
  config = function()
    require 'aerial'.setup {}
    require 'catppuccin'.setup {
      flavour = "mocha",
      integrations = {
        treesitter = true,
      },
      custom_highlights = function(colors)
        return {
          SpecialComment = { fg = colors.green },
        }
      end
    }

    vim.cmd.colorscheme "catppuccin"
    vim.cmd [[
      augroup highlight_yank
          autocmd!
          au TextYankPost * silent! lua vim.highlight.on_yank { higroup='IncSearch', timeout=200 }
      augroup END

      set cmdheight=0
      set laststatus=3
    ]]
  end
}
