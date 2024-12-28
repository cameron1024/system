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
    if vim.g.started_by_firenvim then
      vim.opt.guifont = "FiraCode Nerd Font:12"
    end
  end,
}
