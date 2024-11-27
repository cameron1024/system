return {
  "nvim-treesitter/nvim-treesitter",
  lazy = true,
  event = 'BufReadPost',
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
    "nvim-treesitter/nvim-treesitter-context",
    "theHamsta/crazy-node-movement",
  },
  build = ":TSUpdate",
  config = function()
    local parsers = require 'nvim-treesitter.parsers'.get_parser_configs()

    parsers.just = {
      install_info = {
        url = "https://github.com/IndianBoy42/tree-sitter-just",
        files = { "src/parser.c", "src/scanner.c" },
        branch = "main",
      },
      maintainers = { "@IndianBoy42" },
    }

    parsers.firebase = {
      install_info = {
        url = "https://github.com/ishowta/tree-sitter-firebase-rules",
        files = { "src/parser.c" },
        branch = "main",
      }
    }

    require 'nvim-treesitter.configs'.setup {
      ensure_installed = "all",
      sync_install = false,
      auto_install = true,
      incremental_selection = { enable = false },

      indent = { enable = true, disable = { "dart" }, },

      textobjects = {
        select = {
          enable = true,
          disable = { "dart" },
          lookahead = true,
          keymaps = {
            ["af"] = { query = "@function.outer", desc = "Around Function" },
            ["if"] = { query = "@function.inner", desc = "In Function" },
            ["ac"] = { query = "@class.outer", desc = "Around Class" },
            ["ic"] = { query = "@class.inner", desc = "In Class" },
            ["aa"] = { query = "@parameter.outer", desc = "Around Argument" },
            ["ia"] = { query = "@parameter.inner", desc = "In Argument" },
          },
        },
      },

      node_movement = {
        enable = true,
        keymaps = {
          move_up = "<a-k>",
          move_down = "<a-j>",
          move_left = "<a-h>",
          move_right = "<a-l>",
          swap_left = "<s-a-h>", -- will only swap when one of "swappable_textobjects" is selected
          swap_right = "<s-a-l>",
          select_current_node = "<leader><Cr>",
        },
        swappable_textobjects = { '@function.outer', '@parameter.inner', '@statement.outer' },
        allow_switch_parents = true,
        allow_next_parent = true,
      }
    }

    require 'treesitter-context'.setup {}
  end,
}
