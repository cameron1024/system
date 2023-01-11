local actions = require 'telescope.actions'
local action_layout = require 'telescope.actions.layout'
local telescope = require 'telescope'

telescope.setup {
  layout_strategy = "vertical",
  defaults = {
    mappings = {
      i = {
        ["<esc>"] = actions.close,
        ["<C-s>"] = action_layout.toggle_preview,
      },
    },
  }  
}

telescope.load_extension 'fzf'

local opts = { noremap = true, silent = true }
local map = function(mode, key, action) 
  vim.api.nvim_set_keymap(mode, key, action, opts)
end

map('n', '<leader>n', ':Telescope find_files<CR>')
map('n', '<leader>f', ':Telescope live_grep<CR>')
