return {
    "simrat39/rust-tools.nvim",
    dependencies = {
      "Saecki/crates.nvim",
    },
    event = "BufEnter",
    config = function()
      require 'crates'.setup {}
      require 'rust-tools'.setup {
        server = {
          settings = {
            -- ["rust-analyzer"] = {
            --   procMacro = {
            --     enable = true,
            --   },
            --   cargo = {
            --     features = "all",
            --   },
            --   checkOnSave = {
            --     command = "clippy"
            --   },
            -- },
          },
        },
      }
    end
}
