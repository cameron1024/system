return {
  "nvim-treesitter/nvim-treesitter",
  event = 'BufReadPost',
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  config = function()
    require 'nvim-treesitter.parsers'.get_parser_configs().just = {
      install_info = {
        url = "https://github.com/IndianBoy42/tree-sitter-just",
        files = { "src/parser.c", "src/scanner.c" },
        branch = "main",
      },
      maintainers = { "@IndianBoy42" },
    }

    require 'nvim-treesitter.configs'.setup {
      ensure_installed = "all",
      sync_install = false,
      auto_install = true,
      incremental_selection = { enable = false },

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
            ["gc"] = { query = "@comment.outer", desc = "In Comment" },
          },
        },
      },
    }
  end,
}
