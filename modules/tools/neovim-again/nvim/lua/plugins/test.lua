return {
  "klen/nvim-test",
  event = "BufEnter",
  config = function()
    require 'nvim-test'.setup {
      term = "toggleterm",
      silent = true,
    }
  end
}
