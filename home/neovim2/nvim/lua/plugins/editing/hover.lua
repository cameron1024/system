local hover = function()
	local api = vim.api
	local hover_win = vim.b.hover_preview
	if hover_win and api.nvim_win_is_valid(hover_win) then
		api.nvim_set_current_win(hover_win)
	else
		require "hover".hover()
	end
end


return {
  "lewis6991/hover.nvim",
  lazy = true,
  opts = {
    init = function ()
      require 'hover.providers.lsp'
      require 'hover.providers.gh'
      require 'hover.providers.gh_user'
      require 'hover.providers.fold_preview'
      require 'hover.providers.man'
      require 'hover.providers.dictionary'
    end
  },
  keys = {
    { "gK", function() require 'hover'.hover_switch "next" end },
    { "K", hover },
  }

}
