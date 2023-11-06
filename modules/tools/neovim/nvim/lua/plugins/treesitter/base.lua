return {
  "nvim-treesitter/nvim-treesitter",
  event = 'BufReadPost',
  main = 'nvim-treesitter.configs',
  opts = {
    ensure_installed = { 'rust', 'c', 'dart', 'toml', 'json', 'json5', 'vim', 'vimdoc', 'query' },
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
  }
}
