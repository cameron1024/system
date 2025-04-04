vim.g.rustaceanvim = {
  tools = {
    enable_clippy = true,
    enable_nextest = true,
    reload_workspace_from_cargo_toml = true,
  },
  server = {
    settings = {
      ["rust-analyzer"] = {
        server = {
          path = "rust-analyzer",
        },
        check = {
          command = "clippy",
        },
      },
    },
  },
}

return {
  'mrcjkb/rustaceanvim',
  dependencies = {
    "vxpm/ferris.nvim",
  },
  version = '^4',
  lazy = false,
  ft = { 'rust' },
  config = function()
    require 'ferris'.setup {}
  end,
  keys = {
    { "<C-p>",      "<cmd>RustLsp parentModule<cr>", ft = { "rust" }, },
    -- { "<leader>rm", "<cmd>RustLsp expandMacro<cr>",  desc = "Rust Expand Macro" },
  },
  command = { "RustLsp" },
}
