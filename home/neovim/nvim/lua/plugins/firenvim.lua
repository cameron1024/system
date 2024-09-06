-- init = function()
--   vim.g.firenvim_config = {
--     localSettings = {
--       ['.*'] = { takeover = 'never', priority = 0 },
--     }
--   }
-- end,
return {
  "glacambre/firenvim",
  build = ":call firenvim#install(0)",
}
