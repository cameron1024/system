return {
  "akinsho/toggleterm.nvim",
  dependencies = {
    "chomosuke/term-edit.nvim",
  },
  event = "UIEnter",
  config = function ()
    require 'toggleterm'.setup {
      open_mapping = "<F12>",
      size = 20,
    }

    require 'term-edit'.setup {
      prompt_end = "❯",
    }

  end,
}
