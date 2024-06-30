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
    integrations = {
      aerial = true,
      noice = true,
      neotree = true,
      overseer = true,
      lsp_trouble = true,
    },
  },
}
