return {
  "mfussenegger/nvim-dap",
  -- dependencies = {
  --   "",
  -- },
  event = "BufEnter",
  config = function()
    local dap = require 'dap'.setup {}

  end
}
