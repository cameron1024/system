return {
  "neo451/feed.nvim",
  lazy = true,
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "yuratomo/w3m.vim"
  },
  cmd = {"Feed", "W3m"},
  opts = {
    feeds = {
      "https://neovim.io/news.xml",
      "https://reddit.com/r/rust.rss",
    },
  },
}
