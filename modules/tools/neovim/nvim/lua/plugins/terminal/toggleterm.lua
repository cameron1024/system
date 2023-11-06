return {
  'akinsho/toggleterm.nvim',
  event = "VeryLazy",
  opts = {
    persist_size = false,
    open_mapping = [[<F12>]],
    shell = "nu",
  },
  -- config = function()
  --   local opts = { noremap = true, silent = true }
  --   local map = function(mode, key, action)
  --     vim.keymap.set(mode, key, action, opts)
  --   end
  --
  --   -- map('v', '<C-F12>', ':ToggleTermSendViualSelection')
  -- end,
}
