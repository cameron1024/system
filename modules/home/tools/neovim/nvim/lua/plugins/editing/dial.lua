return {
  "monaqa/dial.nvim",
  lazy = true,
  keys = {
    { "_",  function() require 'dial.map'.manipulate("decrement", "normal") end,  mode = "n", desc = "Decrement" },
    { "+",  function() require 'dial.map'.manipulate("increment", "normal") end,  mode = "n", desc = "Increment" },
    { "g_", function() require 'dial.map'.manipulate("decrement", "gnormal") end, mode = "n", desc = "Decrement" },
    { "g+", function() require 'dial.map'.manipulate("increment", "gnormal") end, mode = "n", desc = "Increment" },
    { "_",  function() require 'dial.map'.manipulate("decrement", "visual") end,  mode = "v", desc = "Decrement" },
    { "+",  function() require 'dial.map'.manipulate("increment", "visual") end,  mode = "v", desc = "Increment" },
    { "g_", function() require 'dial.map'.manipulate("decrement", "gvisual") end, mode = "v", desc = "Decrement" },
    { "g+", function() require 'dial.map'.manipulate("increment", "gvisual") end, mode = "v", desc = "Increment" },
  }
}
