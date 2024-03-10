return {
  'nvim-lualine/lualine.nvim',
  event = "VeryLazy",
  enabled = vim.g.started_by_firenvim == nil,
  config = function()
    if vim.g.started_by_firenvim == true then
      vim.o.laststatus = 0
      return
    end

    vim.o.laststatus = 3

    require 'lualine'.setup {
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = { 'fileformat' },
        lualine_y = { 'aerial' },
        lualine_z = { 'location' }
      },
    }
  end
}
