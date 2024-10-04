return {
  "nvchad/minty",
  dependencies = { "nvchad/volt" },
  lazy = true,
  event = "BufEnter",
  keys = {
    { "<leader>ch", function() require 'minty.huefy'.open() end, desc = "Color Hues" },
    { "<leader>cs", function() require 'minty.shades'.open() end, desc = "Color Shades" },
  }
}
