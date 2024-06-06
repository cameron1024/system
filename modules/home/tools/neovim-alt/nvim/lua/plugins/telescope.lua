return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.5',
  lazy = true,
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
    { "<leader>n",        function() require 'telescope.builtin'.find_files { hidden = true } end, desc = "Telescope Find Files" },
    { "<leader>b",        function() require 'telescope.builtin'.buffers() end,                    desc = "Telescope Buffers" },
    { "<leader>m",        function() require 'telescope.builtin'.lsp_workspace_symbols() end,      desc = "Telescope LSP Symbols" },
    { "<leader>g",        function() require 'telescope.builtin'.grep_string() end,                desc = "Telescope Grep String" },
    { "<leader>f",        function() require 'telescope.builtin'.live_grep() end,                  desc = "Telescope Live Grep" },
    { "<leader>sh",       function() require 'telescope.builtin'.search_history() end,             desc = "Telescope Search History" },
    { "<leader>ch",       function() require 'telescope.builtin'.command_history() end,            desc = "Telescope Command History" },
    { '<leader>"',        function() require 'telescope.builtin'.registers() end,                  desc = "Telescope Registers" },
    { '<leader><leader>', function() require 'telescope.builtin'.resume() end,                     desc = "Telescope Resume" },
  },

}
