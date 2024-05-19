vim.g.mapleader = " "
vim.g.maplocalleader = " "

local options = {
  timeoutlen = 300,
  number = true,
  relativenumber = true,
  hidden = true,
  termguicolors = true,
  fileencoding = "utf-8",
  backup = false,
  swapfile = false,
  hlsearch = true,
  incsearch = true,
  showmode = false,
  expandtab = true,
  shiftwidth = 2,
  tabstop = 2,
  scrolloff = 3,
  sidescrolloff = 3,
  signcolumn = "yes:2",
  ignorecase = true,
  shiftround = true,
  smartcase = true,
  splitbelow = true,
  splitright = true,
  clipboard = "unnamedplus",
  cursorline = true,
  mouse = "a",
  cmdheight = 0,
  undodir = "/tmp/.nvimdid",
  undofile = true,
  updatetime = 50,
  background = "dark",
  laststatus = 3,
  conceallevel = 3,
}

for key, value in pairs(options) do
  vim.opt[key] = value
end

vim.cmd [[
  augroup highlight_yank
      autocmd!
      au TextYankPost * silent! lua vim.highlight.on_yank { higroup='IncSearch', timeout=200 }
  augroup END
]]

