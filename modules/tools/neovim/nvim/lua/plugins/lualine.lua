return {
  'nvim-lualine/lualine.nvim',
  event = "VeryLazy",
  init = function()
    if vim.g.started_by_firenvim == true then
      vim.o.laststatus = 0
      return
    end

    vim.o.laststatus = 3

    local mode = {
      'mode',
    }

    local filename = {
      'filename',
      path = 1,
    }

    require 'lualine'.setup {
      lualine_a = { mode },
      lualine_c = { filename },
    }
  end
}
