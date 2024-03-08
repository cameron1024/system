return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.5',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'nvim-telescope/telescope-frecency.nvim',
    'nvim-telescope/telescope-ui-select.nvim',
    'nvim-telescope/telescope-media-files.nvim',
    'fdschmidt93/telescope-egrepify.nvim',
  },
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
            ["<ESC>"] = actions.close,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
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
        frecency = {
          db_safe_mode = false,
        },
        media_files = {
          find_cmd = "rg",
        },
      },
    }

    telescope.load_extension "frecency"
    telescope.load_extension "ui-select"
    telescope.load_extension "egrepify"
    telescope.load_extension "media_files"
  end,

  cmd = { "Telescope" },

  keys = {
    { "<leader>n",  ":lua require 'telescope.builtin'.find_files()<cr>",            desc = "Telescope Find Files" },
    { "<leader>b",  ":lua require 'telescope.builtin'.buffers()<cr>",               desc = "Telescope Buffers" },
    { "<leader>m",  ":lua require 'telescope.builtin'.lsp_workspace_symbols()<cr>", desc = "Telescope LSP Symbols" },
    { "<leader>g",  ":lua require 'telescope.builtin'.grep_string()<cr>",           desc = "Telescope Grep String" },
    { "<leader>f",  ":lua require 'telescope.builtin'.live_grep()<cr>",             desc = "Telescope Live Grep" },
    { "<leader>sh", ":lua require 'telescope.builtin'.search_history()<cr>",        desc = "Telescope Search History" },
    { "<leader>ch", ":lua require 'telescope.builtin'.command_history()<cr>",       desc = "Telescope Command History" },
    { '<leader>"',  ":lua require 'telescope.builtin'.registers()<cr>",             desc = "Telescope Registers" },
  },

}
