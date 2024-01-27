return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
  event = 'BufReadPost',
  main = 'nvim-treesitter.configs',
  opts = {
    -- ensure_installed = { 'rust', 'c', 'dart', 'toml', 'json', 'json5', 'vim', 'vimdoc', 'query' },
    sync_install = false,
    auto_install = true,

    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },

    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = ",",
        node_incremental = ",",
        scope_incremental = "<C-,>",
        node_decremental = "m",
      },
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["as"] = "@scope",
        },
      },
      move = {
        enable = true,
        set_jumps = true,
      },
      lsp_interop = {
        enable = true,
        border = 'none',
        floating_preview_opts = {},
        peek_definition_code = {
          ["<leader>df"] = "@function.outer",
          ["<leader>dF"] = "@class.outer",
        },
      },
    },
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
  end
}
