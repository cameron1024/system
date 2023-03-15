return {
  "akinsho/toggleterm.nvim",
  event = "UIEnter",
  config = function ()
    require 'toggleterm'.setup {
      open_mapping = "<F12>",
      size = 20,
    }
  end,
}
