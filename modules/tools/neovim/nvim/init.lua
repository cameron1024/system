vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
    lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)


vim.g.firenvim_config = {
  localSettings = {
    ['.*'] = { takeover = 'never', priority = 0 },
  }
}
-- if vim.g.started_from_firenvim == true then
--   vim.g.firenvim_config.localSettings['.*'] = { takeover = 'never' }
-- end


require 'settings'
require 'plugins'
require 'keybinds'
