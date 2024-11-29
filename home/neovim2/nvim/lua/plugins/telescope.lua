return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  lazy = true,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'folke/trouble.nvim',
    'debugloop/telescope-undo.nvim',
    'nvim-telescope/telescope-frecency.nvim',
    'nvim-telescope/telescope-ui-select.nvim',
    'fdschmidt93/telescope-egrepify.nvim',
    '3rd/image.nvim',
  },
  -- dependencies = {
  --   'nvim-lua/plenary.nvim',
  --   'nvim-tree/nvim-web-devicons',
  --   'nvim-telescope/telescope-frecency.nvim',
  --   'nvim-telescope/telescope-ui-select.nvim',
  --   'nvim-telescope/telescope-media-files.nvim',
  --   'fdschmidt93/telescope-egrepify.nvim',
  --   'folke/trouble.nvim',
  --   'debugloop/telescope-undo.nvim',
  -- },
  config = function()
    local telescope = require 'telescope'
    local actions = require 'telescope.actions'

    local default_picker = {
      theme = "ivy",
    }

    telescope.setup {
      defaults = require 'telescope.themes'.get_ivy {
        mappings = {
          i = {
            ["<ESC>"] = actions.close,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-t>"] = require 'trouble.sources.telescope'.open,
            ["<C-space>"] = actions.to_fuzzy_refine,
          }
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
        undo = default_picker,
      },

      extensions = {
        ["ui-select"] = {
          require 'telescope.themes'.get_ivy {},
        },
        frecency = {
          db_safe_mode = false,
        },
        -- media_files = {
        --   find_cmd = "rg",
        -- },
        -- undo = {
        --
        -- }
      },
    }

    telescope.load_extension "frecency"
    telescope.load_extension "ui-select"
    telescope.load_extension "egrepify"
    -- telescope.load_extension "media_files"
    -- telescope.load_extension "undo"
  end,

  cmd = { "Telescope" },

  keys = {
    { "<leader>n",        function() require 'telescope.builtin'.find_files { hidden = true } end, desc = "Telescope Find Files" },
    { "<leader>b",        function() require 'telescope.builtin'.buffers() end,                    desc = "Telescope Buffers" },
    { "<leader>m",        function() require 'telescope.builtin'.lsp_workspace_symbols() end,      desc = "Telescope LSP Symbols" },
    { "<leader>f",        "<CMD>Telescope egrepify<cr>",                                           desc = "Telescope Live Grep" },
    { "<leader>sh",       function() require 'telescope.builtin'.search_history() end,             desc = "Telescope Search History" },
    { '<leader>"',        function() require 'telescope.builtin'.registers() end,                  desc = "Telescope Registers" },
    { '<leader><leader>', function() require 'telescope.builtin'.resume() end,                     desc = "Telescope Resume" },
    { '<leader>u',        "<cmd>Telescope undo<cr>",                                               desc = "Telescope Undo" },
    { "<leader>gc",       function() require 'telescope.builtin'.git_commits() end,                desc = "Telescope Git Commits" },
  },

}
