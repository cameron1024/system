vim.g.mapleader = " "
local disabled_built_ins = {
    "2html_plugin",
    "getscript",
    "getscriptPlugin",
    "gzip",
    "logipat",
    "netrw",
    "netrwPlugin",
    "netrwSettings",
    "netrwFileHandlers",
    "matchit",
    "matchparen",
    "tar",
    "tarPlugin",
    "rrhelper",
    "vimball",
    "vimballPlugin",
    "zip",
    "zipPlugin",
}
local g = vim.g
for _, plugin in pairs(disabled_built_ins) do
  g["loaded_" .. plugin] = 1
end

vim.cmd [[
  filetype plugin indent on
  set laststatus=3
]]

local options = {
    shell = "fish",
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
    cmdheight = 1,
    undodir = "/tmp/.nvimdid",
    undofile = true,
    updatetime = 50,
    background = "dark",
    laststatus = 3,
}

vim.opt.shortmess:append "c"

for key, value in pairs(options) do
  vim.opt[key] = value
end
