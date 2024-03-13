return {
  'numToStr/Comment.nvim',
  lazy = true,
  event = "BufReadPost",
  config = true,
  keys = {
    { 'gc', mode = { 'n', 'v' }, desc = 'Comment' },
    { 'gb', mode = { 'n', 'v' }, desc = 'Block comment' },
  }
}
