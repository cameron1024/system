return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
    "chrisgrieser/nvim-various-textobjs",
    "nvim-treesitter/nvim-treesitter-context",
  },
  event = "BufEnter",
  config = function()
    require 'nvim-treesitter.configs'.setup {
      ensure_installed = { 'rust', 'lua', 'json', 'yaml', 'dart', 'toml', 'nix' },
      auto_install = true,
      highlight = {
        enable = true,
        disable = { "rust" },
        additional_vim_regex_highlighting = false,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = ",", -- set to `false` to disable one of the mappings
          node_incremental = ",",
          scope_incremental = "<C-,>",
          node_decremental = "m",
        },
      },
    }

    require 'various-textobjs'.setup {
      useDefaultKeymaps = true,
    }

    require 'treesitter-context'.setup {}
  end
}
