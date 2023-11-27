return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.4',
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons' },
  event = "VeryLazy",
  config = function()
    local telescope = require 'telescope'
    local actions = require 'telescope.actions'

    telescope.setup {
      defaults = {
        mappings = {
          i = {
            ["<ESC>"] = actions.close
          },
        },
      },
    }


    local map = function(key, action)
      vim.keymap.set('n', key, action, { noremap = true, silent = true })
    end

    local builtin = require 'telescope.builtin'

    map('<leader>n', builtin.find_files)
    map('<leader>b', builtin.buffers)
    map('<leader>m', builtin.lsp_workspace_symbols)
    map('<leader>g', builtin.grep_string)
    map('<leader>f', builtin.live_grep)
    map('<leader>r', builtin.find_files)
    map('<leader>sh', builtin.search_history)
    map('<leader>ch', builtin.search_history)
    map('<leader>"', builtin.registers)
  end

}
