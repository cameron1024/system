return {
  "nvim-treesitter/nvim-treesitter",
  lazy = true,
  event = 'BufReadPost',
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
    "nvim-treesitter/nvim-treesitter-context",
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
    parsers.lean = {
      install_info = {
        url = "https://github.com/Julian/tree-sitter-lean",
        files = { "src/parser.c", "src/scanner.c" },
        branch = "main",
      }
    }
    parsers.cedar = {
      filetype = "cedar",
      install_info = {
        url = "https://github.com/chrnorm/tree-sitter-cedar",
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
    }

    require 'treesitter-context'.setup {}
  end,
}
