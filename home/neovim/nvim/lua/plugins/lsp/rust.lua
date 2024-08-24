vim.g.rustaceanvim = {
  tools = {
    enable_clippy = true,
    enable_nextest = true,
    reload_workspace_from_cargo_toml = true,
  },
  server = {
    -- cmd = { "nix", "run", "nixpkgs#rust-analyzer" },
    settings = {
      -- ["rust-analyzer"] = {
      --   inlayHints = {
      --     bindingModeHints = {
      --       enable = false,
      --     },
      --     chainingHints = {
      --       enable = true,
      --     },
      --     closingBraceHints = {
      --       enable = true,
      --       minLines = 25,
      --     },
      --     closureReturnTypeHints = {
      --       enable = true,
      --     },
      --     lifetimeElisionHints = {
      --       enable = true,
      --       useParameterNames = true,
      --     },
      --     maxLength = 25,
      --     parameterHints = {
      --       enable = true,
      --     },
      --     reborrowHints = {
      --       enable = "never",
      --     },
      --     renderColons = true,
      --     typeHints = {
      --       enable = true,
      --       hideClosureInitialization = false,
      --       hideNamedConstructor = false,
      --     },
      --   },
      -- },
    },
  },
}

return {
  'mrcjkb/rustaceanvim',
  dependencies = {
    "vxpm/ferris.nvim",
  },
  version = '^4',
  lazy = true,
  ft = { 'rust' },
  config =function ()
   require 'ferris'.setup {

   } 
  end,
  keys = {
    { "<C-p>",      "<cmd>RustLsp parentModule<cr>", desc = "Rust Parent Module" },
    { "<leader>rm", "<cmd>RustLsp expandMacro<cr>",  desc = "Rust Expand Macro" },
  },
  command = "RustLsp",
}
