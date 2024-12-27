local home = vim.fn.expand("~/notes");

return {
  "nvim-telekasten/telekasten.nvim",
  lazy = true,
  dependencies = { 'nvim-telescope/telescope.nvim' },
  cmd = { "Telekasten" },
  opts = {
    home = home,
    dailies = home .. "/daily",
    weeklies = home .. "/weekly",
    templates = home .. "/templates",

    auto_set_filetype = false,
  },
  keys = {
    { "``", "<cmd>Telekasten<cr>" },
    { "`n", "<cmd>Telekasten new_note<cr>" },
    { "`s", "<cmd>Telekasten search_in_notes<cr>" },
  }
}
