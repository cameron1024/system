vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.timeoutlen = 300
opt.number = true
opt.relativenumber = true
opt.hidden = true
opt.termguicolors = true
opt.fileencoding = "utf-8"
opt.backup = false
opt.swapfile = false
opt.hlsearch = true
opt.incsearch = true
opt.showmode = false
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.scrolloff = 3
opt.sidescrolloff = 3
opt.signcolumn = "yes:2"
opt.ignorecase = true
opt.shiftround = true
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true
opt.clipboard = "unnamedplus"
opt.cursorline = true
opt.mouse = "a"
opt.cmdheight = 0
opt.undodir = "/tmp/.nvimdid"
opt.undofile = true
opt.updatetime = 50
opt.background = "dark"
opt.laststatus = 3
opt.conceallevel = 3
opt.shell = "fish"

vim.cmd [[
  augroup highlight_yank
      autocmd!
      au TextYankPost * silent! lua vim.highlight.on_yank { higroup='IncSearch', timeout=200 }
  augroup END
]]

