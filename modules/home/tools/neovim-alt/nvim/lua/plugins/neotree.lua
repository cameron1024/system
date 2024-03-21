return {
  'nvim-neo-tree/neo-tree.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
    require 'plugins.editing.image-view',
    { 's1n7ax/nvim-window-picker', lazy = true, opts = { hint = "floating-big-letter" } },
  },
  opts = {
    close_if_last_window = true,
    filesystem = {
      filtered_items = {
        visible = true,
      },
    },
    window = {
      mappings = {
        ["e"] = "image_wezterm",
      },
    },
    commands = {
      image_wezterm = function(state)
        local node = state.tree:get_node()
        if node.type == "file" then
          require("image_preview").PreviewImage(node.path)
        end
      end,
    },
  },
  cmd = { "Neotree" },
  keys = {
    { "<leader>p", ":Neotree toggle reveal_force_cwd<CR>", desc = "Open Neotree" },
  },
}
