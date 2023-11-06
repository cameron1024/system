return {
  'nvim-lualine/lualine.nvim',
  event = "VeryLazy",
  init = function()
    if vim.g.started_by_firenvim == true then
      vim.o.laststatus = 0
      return
    end

    vim.o.laststatus = 3

    local mode_map = {
      ["n"] = "[N]",
      ["i"] = "[I]",
      ["v"] = "[V]",
    };

    local function modes()
      return mode_map[vim.api.nvim_get_mode().mode] or "[?]"
    end

    require 'lualine'.setup {
      lualine_a = { modes },
    }
  end
}
