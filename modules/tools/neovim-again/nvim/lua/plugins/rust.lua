return {
    "simrat39/rust-tools.nvim",
    dependencies = {
      "Saecki/crates.nvim",
    },
    event = "BufEnter",
    config = function()
      require 'crates'.setup {}
      require 'rust-tools'.setup {
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
              procMacro = {
                enable = true,
              },
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
    end
}
