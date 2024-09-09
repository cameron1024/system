return {
  'okuuva/auto-save.nvim',
  lazy = true,
  event = "BufEnter",
  opts = {
    write_all_buffers = true,
    debounce_delay = 10,
    execution_message = {
    }
  },
}
