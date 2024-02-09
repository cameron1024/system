return {
  "folke/trouble.nvim",
  event = "BufEnter",
  config = function()
    require 'trouble'.setup {}
  end
}
