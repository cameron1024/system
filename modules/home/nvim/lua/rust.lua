require('rust-tools').setup {
  server = {
    settings = {
      ["rust-analyzer"] = {
        rustcSource = "discover",
        cargo = {
          features = "all",
          loadOutDirsFromCheck = true,
        },
        checkOnSave = {
          command = "clippy"
        },
        diagnostics = {
          disabled = { "inactive-code" }
        },
      }
		}
	},
}

require 'rust-tools'.inlay_hints.enable()

require 'crates'.setup {} 
