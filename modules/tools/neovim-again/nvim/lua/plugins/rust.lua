return {
    "simrat39/rust-tools.nvim",
    event = "BufEnter",
    config = function()
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
