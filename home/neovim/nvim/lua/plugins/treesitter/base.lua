return {
  "nvim-treesitter/nvim-treesitter",
  event = 'BufReadPost',
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
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
      ignore_install = { "tlaplus", "liquidsoap", "norg", "dart" },

      textobjects = {
        select = {
          enable = true,
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
  end,
}
