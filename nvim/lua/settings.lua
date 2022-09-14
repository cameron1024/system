vim.cmd [[filetype plugin indent on]]

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
    pumheight = 10,
    laststatus = 3,
    updatetime = 50,
    background = "dark",
    grepprg = "rg --hidden"
}

vim.opt.shortmess:append "c"

for key, value in pairs(options) do
    vim.opt[key] = value
end


