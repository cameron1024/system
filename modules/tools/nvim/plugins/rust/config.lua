require('rust-tools').setup {
  server = {
    settings = {
      ["rust-analyzer"] = {
        rustcSource = "discover",
        cargo = {
          features = "all",
          loadOutDirsFromCheck = true,
        },
        -- checkOnSave = {
        --   command = "clippy"
        -- },
        diagnostics = {
          disabled = { "inactive-code" }
        },
      }
		}
	},
}

