return {
  'catppuccin/nvim',
  name = 'catppuccin',
  init = function()
    vim.cmd.colorscheme "catppuccin"
  end,
  opts = {
    background = {
      light = "latte",
      dark = "mocha",
    },
  },
}
