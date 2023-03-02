local opts = {
  -- rust-tools options
  tools = {
    inlay_hints = {
      show_parameter_hints = true,
      parameter_hints_prefix = "",
      other_hints_prefix = "",
      },
    },

  server = {
    settings = {
      ["rust-analyzer"] = {
        cargo = {
          features = "all",
        },
        checkOnSave = {
          command = "clippy"
        },
      },
    },
  },
}

require('rust-tools').setup(opts)
