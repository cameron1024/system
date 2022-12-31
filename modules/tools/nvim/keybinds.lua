vim.g.mapleader = " "

local opts = { noremap = true, silent = true }
local map = function(mode, key, action) 
  vim.keymap.set(mode, key, action, opts)
end

-- telescope pickers
map('n', '<leader>n', ':Telescope find_files<CR>')
map('n', '<leader>f', ':Telescope live_grep<CR>')
map('n', '<leader>b', ':Telescope buffers<CR>')
map('n', '<leader>d', ':Telescope diagnostics<CR>')
map('n', '`', ':Telescope commands<CR>')

-- neotree
map('n', '<leader>p', ':Neotree toggle reveal_force_cwd<CR>')

-- saving and closing
map('n', '<leader>q', ':x<CR>')
map('n', '<leader>Q', ':wqa<CR>')
map('n', '<leader>w', ':wa<CR>')

-- window management
map('n' ,'<leader><Tab>', '<C-^>')
map('n', '<C-v>', ':vs<CR>')
map('n', '<C-x>', ':sp<CR>')

-- remap <C-v> for block select mode
map('n', '<leader>v', '<C-v>')

-- ctrl + hjkl to switch panes
map('n', '<C-k>', '<C-w><Up>')
map('n', '<C-j>', '<C-w><Down>')
map('n', '<C-h>', '<C-w><Left>')
map('n', '<C-l>', '<C-w><Right>')

-- ctrl + hjkl to move in insert mode
map('i', '<C-k>', '<Up>')
map('i', '<C-j>', '<Down>')
map('i', '<C-h>', '<Left>')
map('i', '<C-l>', '<Right>')

-- shift + hl to move far in normal mode
map('n', 'H', '0')
map('n', 'L', '$')

-- indenting selections without deselecting
map('v', '<', '<gv')
map('v', '>', '>gv')

-- deselect
map('n', '<C-d>', ':nohl<CR>')
map('i', '<C-d>', '<C-o>:nohl<CR>')

-- make * stay on the same entry
map('n', '*', '*N')

-- why is escape not the default "get out of terminal" bind...
map('t', '<ESC>', '<C-\\><C-n>')
map('t', '<C-h>', [[<Cmd>wincmd h<CR>]])
map('t', '<C-j>', [[<Cmd>wincmd j<CR>]])
map('t', '<C-k>', [[<Cmd>wincmd k<CR>]])
map('t', '<C-l>', [[<Cmd>wincmd l<CR>]])

-- yank current file path
map('n', '<leader>cf', ':let @+ = expand("%")<CR>')
map('n', '<leader>cp', ':let @+ = expand("%:p")<CR>')

-- ; -> :
map('n', ';', ':')

-- lsp

-- diagnostics
map('n', '<C-n>', vim.diagnostic.goto_next)
map('n', '<C-b>', vim.diagnostic.goto_prev)
map('n', 'E', vim.diagnostic.open_float)
map('n', 'Q', vim.diagnostic.setloclist)
map('n', '<leader>e', ':TroubleToggle workspace_diagnostics<CR>')

-- goto
map('n', 'gd', vim.lsp.buf.definition)
map('n', 'gD', vim.lsp.buf.declaration)
map('n', 'gi', vim.lsp.buf.implementation)
map('n', 'gt', vim.lsp.buf.type_definition)
map('n', 'gr', vim.lsp.buf.references)

-- actions
map('n', '<F2>', vim.lsp.buf.rename)
map('n', '<leader>a', vim.lsp.buf.code_action)
map('n', '<MS-f>', function() vim.lsp.buf.format { async = true } end)
map('n', 'K', vim.lsp.buf.hover)

map('n', '<C-p>', ':lua require "rust-tools".parent_module.parent_module()<CR>')
map('n', '<C-m>', ':lua require "rust-tools".expand_macro.expand_macro()<CR>')
