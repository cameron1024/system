return {
  "glacambre/firenvim",
  build = ":call firenvim#install(0)",
  tag = "0.2.16",
  init = function()
    vim.g.firenvim_config = {
      localSettings = {
        ['.*'] = { takeover = 'never', priority = 0 },
      }
    }
  end,
}
