return {
  "kylechui/nvim-surround",
  dependencies = {
    "terrortylor/nvim-comment",
  },
  event = "BufEnter",
  config = function ()
    require 'nvim-surround'.setup {}
    require 'nvim_comment'.setup {}
  end
}
