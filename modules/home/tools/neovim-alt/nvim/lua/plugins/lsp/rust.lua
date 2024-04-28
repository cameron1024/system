vim.g.rustaceanvim = {
  tools = {
    enable_clippy = true,
    enable_nextest = true,
    reload_workspace_from_cargo_toml = true,
  },
  server = {
    cmd = { "nix", "run", "nixpkgs#rust-analyzer" },
  },
}

return {
  'mrcjkb/rustaceanvim',
  version = '^4',
  lazy = true,
  ft = { 'rust' },
  keys = {
    { "<C-p>",      "<cmd>RustLsp parentModule<cr>", desc = "Rust Parent Module" },
    { "<leader>rm", "<cmd>RustLsp expandMacro<cr>",  desc = "Rust Expand Macro" },
  },
  command = "RustLsp",
}
