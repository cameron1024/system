return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.4',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'nvim-telescope/telescope-frecency.nvim',
    'nvim-telescope/telescope-ui-select.nvim',
    'fdschmidt93/telescope-egrepify.nvim',
  },
  event = "VeryLazy",
  config = function()
    local telescope = require 'telescope'
    local actions = require 'telescope.actions'

    local default_picker = {
      theme = "ivy",
    }

    telescope.setup {
      defaults = {
        mappings = {
          i = {
            ["<ESC>"] = actions.close
          },
        },
      },

      pickers = {
        find_files = default_picker,
        buffers = default_picker,
        lsp_workspace_symbols = default_picker,
        grep_string = default_picker,
        live_grep = default_picker,
        search_history = default_picker,
        command_history = default_picker,
        registers = default_picker,
      },

      extensions = {
        ["ui-select"] = {
          require 'telescope.themes'.get_dropdown {},
        },
        frecency = {},
      },
    }

    telescope.load_extension "frecency"
    telescope.load_extension "ui-select"
    telescope.load_extension "egrepify"


    local map = function(key, action)
      vim.keymap.set('n', key, action, { noremap = true, silent = true })
    end

    local builtin = require 'telescope.builtin'

    map('<leader>n', builtin.find_files)
    map('<leader>b', builtin.buffers)
    map('<leader>m', builtin.lsp_workspace_symbols)
    map('<leader>g', builtin.grep_string)
    map('<leader>f', builtin.live_grep)
    map('<leader>sh', builtin.search_history)
    map('<leader>ch', builtin.command_history)
    map('<leader>"', builtin.registers)
  end

}
