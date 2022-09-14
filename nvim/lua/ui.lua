require 'fidget'.setup {}     -- loading indicator for LSP
require 'colorizer'.setup {}  -- makes #123456 appear as an actual color
require 'lsp_lines'.setup {}  -- better diagnostics
vim.diagnostic.config { virtual_text = false }

require 'treesitter-context'.setup {}
require 'toggleterm'.setup {
  open_mapping = "<F12>",
  size = 20,
}

require 'dressing'.setup {
  select = {
    backend = { 'builtin' }
  }
}

require 'iswap'.setup {}

-- outline view + remapping some movements
require 'aerial'.setup {  
  on_attach = function(bufnr)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>o', '<cmd>AerialToggle!<CR>', {})
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '{', '<cmd>AerialPrev<CR>', {})
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '}', '<cmd>AerialNext<CR>', {})
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '[[', '<cmd>AerialPrevUp<CR>', {})
    vim.api.nvim_buf_set_keymap(bufnr, 'n', ']]', '<cmd>AerialNextUp<CR>', {})
    vim.api.nvim_buf_set_keymap(bufnr, 'v', '{', '<cmd>AerialPrev<CR>', {})
    vim.api.nvim_buf_set_keymap(bufnr, 'v', '}', '<cmd>AerialNext<CR>', {})
    vim.api.nvim_buf_set_keymap(bufnr, 'v', '[[', '<cmd>AerialPrevUp<CR>', {})
    vim.api.nvim_buf_set_keymap(bufnr, 'v', ']]', '<cmd>AerialNextUp<CR>', {})
  end
}
require 'nvim-tree'.setup {}

local lualine_colors = {
  black        = colors.base00,
  white        = colors.base05,
  red          = colors.base08,
  green        = colors.base0B,
  blue         = colors.base0D,
  yellow       = colors.base0A,
  gray         = colors.base04,
  darkgray     = colors.base01,
  lightgray    = colors.base02,
  inactivegray = colors.base03,
}

require 'lualine'.setup {
 sections = {
		lualine_a = {
			{'filename', path = 1, shorting_target = 50}
		},
		lualine_b = { 'diff', 'branch' },
		lualine_c = { {'diagnostics', sources = { 'nvim_lsp', 'nvim_diagnostic' } }, },
		lualine_x = { 'filetype' },
		lualine_y = { 'aerial' },
	},
  options = {
    theme = {
      normal = {
        a = {bg = lualine_colors.gray, fg = lualine_colors.black, gui = 'bold'},
        b = {bg = lualine_colors.lightgray, fg = lualine_colors.white},
        c = {bg = lualine_colors.darkgray, fg = lualine_colors.gray}
      },
      insert = {
        a = {bg = lualine_colors.blue, fg = lualine_colors.black, gui = 'bold'},
        b = {bg = lualine_colors.lightgray, fg = lualine_colors.white},
        c = {bg = lualine_colors.lightgray, fg = lualine_colors.white}
      },
      visual = {
        a = {bg = lualine_colors.yellow, fg = lualine_colors.black, gui = 'bold'},
        b = {bg = lualine_colors.lightgray, fg = lualine_colors.white},
        c = {bg = lualine_colors.inactivegray, fg = lualine_colors.black}
      },
      replace = {
        a = {bg = lualine_colors.red, fg = lualine_colors.black, gui = 'bold'},
        b = {bg = lualine_colors.lightgray, fg = lualine_colors.white},
        c = {bg = lualine_colors.black, fg = lualine_colors.white}
      },
      command = {
        a = {bg = lualine_colors.green, fg = lualine_colors.black, gui = 'bold'},
        b = {bg = lualine_colors.lightgray, fg = lualine_colors.white},
        c = {bg = lualine_colors.inactivegray, fg = lualine_colors.black}
      },
      inactive = {
        a = {bg = lualine_colors.darkgray, fg = lualine_colors.gray, gui = 'bold'},
        b = {bg = lualine_colors.darkgray, fg = lualine_colors.gray},
        c = {bg = lualine_colors.darkgray, fg = lualine_colors.gray}
      }
    },
  },
}

require'nvim-treesitter.configs'.setup {
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
      ["<leader>23"] = "@parameters.outer",
		},
	},
}

vim.cmd[[
augroup highlight_yank
    autocmd!
    au TextYankPost * silent! lua vim.highlight.on_yank { higroup='IncSearch', timeout=200 }
augroup END
]]
