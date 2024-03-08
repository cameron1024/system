return {
  "nvim-treesitter/nvim-treesitter",
  event = 'BufReadPost',
  main = 'nvim-treesitter.configs',
  opts = {
    -- lua one is broken
    ensure_installed = "all",
    sync_install = false,
    auto_install = true,
    -- parser_install_dir = "~/.local/share/treesitter/parsers",
  },
  config = function()
    -- vim.opt.runtimepath:append("~/.local/share/treesitter/parsers")

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
