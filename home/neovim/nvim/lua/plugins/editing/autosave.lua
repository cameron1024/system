return {
  'pocco81/auto-save.nvim',
  lazy = true,
  event = "BufEnter",
  opts = {
    write_all_buffers = true,
    debounce_delay = 10,
  },
}
