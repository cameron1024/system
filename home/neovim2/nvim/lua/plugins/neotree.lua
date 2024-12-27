return {
  'nvim-neo-tree/neo-tree.nvim',
  lazy = true,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
    { 's1n7ax/nvim-window-picker', lazy = true, opts = { hint = "floating-big-letter" } },
    -- "image.nvim"
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
        -- ["P"] = { "toggle_preview", config = { use_float = true  } },
      },
    },
  },
  cmd = { "Neotree" },
  keys = {
    { "<leader>p", ":Neotree toggle reveal_force_cwd<CR>", desc = "Open Neotree" },
  },
}
