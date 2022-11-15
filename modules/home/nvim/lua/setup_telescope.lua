local trouble = require 'trouble'
local actions = require 'telescope.actions'
local action_layout = require 'telescope.actions.layout'

require 'telescope'.setup {
  layout_strategy = "vertical",
  defaults = {
    file_ignore_patterns = { ".git" },
    mappings = {
      n = { 
        ["<c-t>"] = trouble.open_with_trouble
      },
      i = {
        ["<esc>"] = actions.close,
        ["<C-s>"] = action_layout.toggle_preview,
        ["<c-t>"] = trouble.open_with_trouble,
      },
    },
  }  
}
