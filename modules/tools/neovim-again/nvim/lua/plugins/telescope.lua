return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.1',
  dependencies = {
    'nvim-telescope/telescope-frecency.nvim',
    'nvim-lua/plenary.nvim',
    "LinArcX/telescope-env.nvim",
    "LinArcX/telescope-env.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make", },
  },
  config = function()
    local actions = require 'telescope.actions'
    local action_layout = require 'telescope.actions.layout'
    local telescope = require 'telescope'


    telescope.setup {
      layout_strategy = "vertical",


      extensions = {
        fzf = {
          fuzzy = true,                   -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true,    -- override the file sorter
          case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
        },
      },

      defaults = {
        mappings = {
          i = {
            ["<esc>"] = actions.close,
            ["<C-s>"] = action_layout.toggle_preview,
            -- ["<C-k>"] = action_layout.move_selection_next,
            -- ["<C-j>"] = action_layout.move_selection_previous,
          },
        },
      }
    }

    telescope.load_extension 'env'
    telescope.load_extension "frecency"

    local opts = { noremap = true, silent = true }
    local map = function(mode, key, action)
      vim.api.nvim_set_keymap(mode, key, action, opts)
    end

    map('n', '<leader>n', ':Telescope find_files<CR>')
    map('n', '<leader>f', ':Telescope live_grep<CR>')
    map('n', '<leader>b', ':Telescope buffers<CR>')
    map('n', '<leader>d', ':Telescope diagnostics<CR>')
    map('n', '<leader>g', ':Telescope resume<CR>')
    map('n', '<leader>t', ':Telescope frecency<CR>')
    map('n', '`', ':Telescope commands<CR>')
  end
}
