return {
  'norcalli/nvim-colorizer.lua',
  event = "VeryLazy",
  config = function()
    require 'colorizer'.setup({}, {
      named = false,
      RRGGBBAA = true,
    })

    vim.cmd 'ColorizerToggle'
  end,
}
