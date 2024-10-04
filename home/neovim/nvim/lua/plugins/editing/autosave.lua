return {
  'https://git.sr.ht/~nedia/auto-save.nvim',
  lazy = true,
  event = "BufReadPre",
  opts = {
    events = { "InsertLeave", "BufLeave" },
    silent = true,
  },
}
