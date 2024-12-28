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
  conceallevel = 3,
  shell = "fish",
  autowriteall = true,
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


if vim.g.neovide then
  vim.o.guifont = "FiraCode Nerd Font:h14"

  vim.keymap.set("n", "<C-+>", function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 1.25 end)
  vim.keymap.set("n", "<C-_>", function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor / 1.25 end)
end
