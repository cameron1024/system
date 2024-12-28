if vim.g.started_by_firenvim == true then
  vim.o.laststatus = 0
else
  vim.o.laststatus = 3
end

local mode_map = {
  ["n"] = "N",
  ["no"] = "O·P",
  ["nov"] = "O·P",
  ["noV"] = "O·P",
  ["no\22"] = "O·P",
  ["niI"] = "N·I",
  ["niR"] = "N·R",
  ["niV"] = "N",
  ["nt"] = "N·T",
  ["v"] = "V",
  ["vs"] = "V",
  ["V"] = "V·L",
  ["Vs"] = "V·L",
  ["\22"] = "V·B",
  ["\22s"] = "V·B",
  ["s"] = "S",
  ["S"] = "S·L",
  ["\19"] = "S·B",
  ["i"] = "I",
  ["ic"] = "I·C",
  ["ix"] = "I·X",
  ["R"] = "R",
  ["Rc"] = "R·C",
  ["Rx"] = "R·X",
  ["Rv"] = "V·R",
  ["Rvc"] = "RVC",
  ["Rvx"] = "RVX",
  ["c"] = "C",
  ["cv"] = "EX",
  ["ce"] = "EX",
  ["r"] = "R",
  ["rm"] = "M",
  ["r?"] = "C",
  ["!"] = "SH",
  ["t"] = "T",
}

local function modes()
  return mode_map[vim.api.nvim_get_mode().mode] or "__"
end

return {
  'nvim-lualine/lualine.nvim',
  -- dependencies = {
  --   "stevearc/aerial.nvim",
  -- },
  event = "UIEnter",
  enabled = vim.g.started_by_firenvim == nil,
  config = function()
    require 'lualine'.setup {
      options = {
        theme = require 'lualine.themes.everforest',
        component_separators = { left = "|", right = "|", },
        section_separators = { left = "", right = "", },
      },
      sections = {
        lualine_a = { modes },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = {},
        lualine_y = {},
        lualine_z = { 'location' }
      },
    }
  end
}
