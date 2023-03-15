return {
  "akinsho/flutter-tools.nvim",
  dependencies = {
    "stevearc/dressing.nvim",
  },
  event = "BufEnter",
  config = function ()
    require 'flutter-tools'.setup {}
  end
}
