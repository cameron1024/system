-- return {
--   'sainnhe/everforest',
--   lazy = false,
--   priority = 1000,
--   config = function()
--     vim.g.everforest_background = 'hard'
--     vim.cmd.colorscheme 'everforest'
--   end
-- }
--
return {
  "neanias/everforest-nvim",
  lazy = false,
  version = false,
  priority = 1000,
  config = function ()
    vim.cmd.colorscheme "everforest"
  end,
}
