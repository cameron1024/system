local detail = false

return {
  'stevearc/oil.nvim',
  lazy = true,
  opts = {
    default_file_explorer = true,
    columns = {
      "icon",
      "size",
    },
    keymaps = {
      ["<C-t>"] = false,
      ["<leader>p"] = false,
      ["<C-p>"] = "actions.parent",
      ["<C-v>"] = false,
      ["<C-x>"] = false,
      ["<C-h>"] = false,
      ["<C-j>"] = false,
      ["<C-k>"] = false,
      ["<C-l>"] = false,
      ["K"] = "actions.preview",
      ["-"] = "actions.close",
      ["gd"] = {
        desc = "Toggle file detail view",
        callback = function()
          detail = not detail
          if detail then
            require "oil".set_columns { "icon", "size", "permissions", "mtime" }
          else
            require "oil".set_columns { "icon", "size" }
          end
        end,
      },
    },
    view_options = {
      show_hidden = true,
      natural_order = "fast",
    },
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = { "Oil" },
  keys = {
    { "-", function() require 'oil'.open_float() end, desc = "Oil" }
  },
}
