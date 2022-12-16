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
