return {
  'pocco81/auto-save.nvim',
  event = "BufEnter",
  opts = {
    write_all_buffers = true,
    debounce_delay = 10,
  },
}
