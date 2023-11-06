return {
  'smjonas/inc-rename.nvim',
  event = 'VeryLazy',
  opts = {},
  config = function()
    vim.keymap.set("n", "<f2>", function()
      return ":IncRename " .. vim.fn.expand("<cword>")
    end, { expr = true })
  end
}
