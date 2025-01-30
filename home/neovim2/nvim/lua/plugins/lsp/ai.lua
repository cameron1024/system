return {
  "yetone/avante.nvim",
  lazy = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "OXY2DEV/markview.nvim",
  },
  build = "make",
  cmd = { "AvanteAsk" },
  opts = {
    provider = "ollama",
    vendors = {
      ollama = {
        __inherited_from = "openai",
        api_key_name = "",
        endpoint = "http://127.0.0.1:11434/v1",
        model = "deepseek-r1:8b",
      },
    }
  },
}
