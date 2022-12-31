require 'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
		additional_vim_regex_highlighting = false,
		disable = { "rust" },  -- rust-tools provides better highlighting
  },
  textobjects = {
    select = {
      enable = true,

      -- Automatically jump forward to textobj, similar to targets.vim 
      lookahead = true,

      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
      },
    },
  },
	incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = ",",
      node_incremental = ",",
      scope_incremental = "<C-,>",
      node_decremental = "m",
    },
  },
	rainbow = {
		enable = false
	},
	move = {
		enable = true,
		set_jumps = true, -- whether to set jumps in the jumplist
		goto_next_start = {
			["]m"] = "@function.outer",
			["]]"] = "@class.outer",
		},
		goto_next_end = {
			["]M"] = "@function.outer",
			["]["] = "@class.outer",
		},
		goto_previous_start = {
			["[m"] = "@function.outer",
			["[["] = "@class.outer",
		},
		goto_previous_end = {
			["[M"] = "@function.outer",
			["[]"] = "@class.outer",
		},
	},
}
