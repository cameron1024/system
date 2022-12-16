local function map(mode, lhs, rhs) 
  local options = { silent = true, noremap = true }
  -- return vim.api.nvim_set_keymap(mode, lhs, rhs, options)
  return vim.keymap.set(mode, lhs, rhs, options)
end

vim.g.mapleader = " "  -- leader key is used in a lot of bindings, I like space because it's big and always within reach 

map('n', 'H', '^')
map('v', 'H', '^')
map('n', 'L', '$')
map('v', 'L', '$')

map('n', '`', ':Telescope commands<CR>')
map('n', 'q', '')

map('n', '#', ':set relativenumber!<CR>')

map('i', '<C-CR>', '<Esc>o')
map('i', 'jj', '<Esc>')

map('i', '<C-BS>', '<C-w>')
map('i', '<S-CR>', '<C-o>o')
map('n', '<leader>0', 'ia<C-c>u')  -- lsp sometimes gets stuck, this helps refresh it
map('n', ';', ':')
map('n' ,'<leader><Tab>', '<C-^>')

map('n', '<leader>s', ':ISwapWith<CR>')
map('n', '<C-f>', ':TSContextToggle<CR>')
map('n', '<C-d>', ':nohlsearch<CR>')
map('v', '<C-d>', ':nohlsearch<CR>')
map('n', '<C-g>', ':%s/')
map('n', '<C-s>', ':%s/\\<<C-r><C-w>\\>/')
map('n', '<C-v>', ':vs<CR>')
map('n', '<C-x>', ':sp<CR>')
map('n', '<leader>u', ':%s/\\r//g<CR>')  -- when copy/pasting from windows, you get CRLF newlines, this fixes them


map('n', '<leader>w', ':wa<CR>')
map('n', '<leader>q', ':x<CR>')
map('n', '<C-q>', ':x<CR>')
map('n', '<leader><F4>', ':xa<CR>')
map('n', '<leader>;', '@:')
map('n', '<leader>v', '<C-v>')

-- fix decrement conflict with tmux prefix
map('n', '<C-z>', '<C-a>')
map('i', '<C-z>', '<C-a>')

-- * in visual mode searches for occurrences of selected chunk
map('v', '*', [[y/\V<C-R>=escape(@",'/\')<CR><CR>]])

-- search
map('n', '<leader>f', ':Telescope live_grep<CR>')
map('n', '<leader>b', ':Telescope buffers<CR>')
map('n', '<leader>n', ':Telescope find_files hidden=true no_ignore=false<CR>')
map('n', '<leader>N', ':Telescope find_files hidden=true no_ignore=true<CR>')
map('n', '<leader>p', ':NvimTreeFindFileToggle<CR>')

-- tests
map('n', '<leader>tn', ':TestNearest<CR>')
map('n', '<leader>tf', ':TestFile<CR>')
map('n', '<leader>ts', ':TestSuite<CR>')
map('n', '<leader>tl', ':TestLast<CR>')
map('n', '<leader>tv', ':TestVisit<CR>')

-- cool git stuff
map('n', '<leader>gb', ':GitBlameToggle<CR>')
map('n', '<leader>gt', ':lua require("agitator").git_time_machine()<CR>')
map('n', '<leader>gf', ':lua require("agitator").open_file_git_branch()<CR>')
map('n', '<leader>gc', ':GitConflictListQf<CR>')


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

map('i', '<C-;>', '<C-o><S-Right>a;')

-- indenting selections without deselecting
map('v', '<', '<gv')
map('v', '>', '>gv')

-- make * stay on the same entry
map('n', '*', '*N')

-- why is escape not the default "get out of terminal" bind...
map('t', '<ESC>', '<C-\\><C-n>')

-- yank current file path
map('n', '<leader>cf', ':let @+ = expand("%")<CR>')
map('n', '<leader>cp', ':let @+ = expand("%:p")<CR>')

-- lsp keybinds
map('n', 'K', ':lua vim.lsp.buf.hover()<CR>')
map('n', '<C-p>', ':lua vim.lsp.buf.signature_help()<CR>')
map('n', '[g', ':lua vim.diagnostic.goto_prev({ focusable = false })<CR>')
map('n', ']g', ':lua vim.diagnostic.goto_next({ focusable = false })<CR>')
map('n', '<C-b>', ':lua vim.diagnostic.goto_prev({ focusable = false })<CR>')
map('n', '<C-n>', ':lua vim.diagnostic.goto_next({ focusable = false })<CR>')
map('n', '<leader>e', ':TroubleToggle workspace_diagnostics<CR>')
map('n', '<leader>E', ':TroubleToggle document_diagnostics<CR>')
map('n', 'gr', ':TroubleToggle lsp_references<CR>')
map('i', '<F2>', ':lua vim.lsp.buf.rename()<CR>')
map('n', '<F2>', ':lua vim.lsp.buf.rename()<CR>')
map('n', '<leader>rn', ':lua require("renamer").rename()<CR>')
map('n', '<leader>a', ':lua vim.lsp.buf.code_action()<CR>')
map('n', '<C-.>', ':lua vim.lsp.buf.code_action()<CR>')
map('i', '<C-.>', ':lua vim.lsp.buf.code_action()<CR>')
map('n', '<leader>m', ':Telescope lsp_workspace_symbols<CR>')
map('n', 'gd', ':lua vim.lsp.buf.definition()<CR>')
map('n', 'gt', ':Telescope lsp_type_definitions<CR>')
map('n', 'gi', ':Telescope lsp_implementations<CR>')
map('n', '<SM-f>', ':Format<CR>')
map('n', '<leader>r', ':Telescope resume<CR>')
map('n', '<MS-f>', ':lua vim.lsp.buf.format { async = true }<CR>')

-- diagnostic
map('n', '<C-e>', require 'lsp_lines'.toggle)
map('i', '<C-e>', require 'lsp_lines'.toggle)

-- hook into autocomplete in insert mode
vim.api.nvim_set_keymap('i', '<cr>', 'compe#confirm("<cr>")', { expr = true })
vim.api.nvim_set_keymap('i', '<c-space>', 'compe#complete()', { expr = true })

-- tab stuff
map('n', '<C-t><C-k>', ':tabnext<CR>')
map('n', '<C-t><C-j>', ':tabprevious<CR>')
map('n', '<C-t><C-n>', ':tabnew<CR>')
map('n', '<C-t><C-o>', ':tabo<CR>')

-- debugging
map('n', '<leader>da', ":lua require'dap'.toggle_breakpoint()<CR>")
map('n', '<leader>dd', ":lua require'dapui'.toggle()<CR>")
map('n', '<leader>de', ":lua require'dapui'.eval()<CR>")
map('n', '<F5>', ":lua require'dap'.continue()<CR>")
map('n', '<F6>', ":lua require'dap'.step_over()<CR>")
map('n', '<F7>', ":lua require'dap'.step_into()<CR>")
map('n', '<F8>', ":lua require'dap'.terminate()<CR>")

-- assorted ui stuff
map('n', '<F10>', ':setlocal spell! spelllang=en_gb<CR>')
map('i', '<F11>', ":ZenMode<CR>")
map('n', '<F11>', ":ZenMode<CR>")
map('i', '<S-F11>', ":Twilight<CR>")
map('n', '<S-F11>', ":Twilight<CR>")

-- language specific
map('n', '<C-p>', ':RustParentModule<CR>')

-- treesitter
vim.api.nvim_set_keymap('x', 'iu', ':lua require"treesitter-unit".select()<CR>', {noremap=true})
vim.api.nvim_set_keymap('x', 'au', ':lua require"treesitter-unit".select(true)<CR>', {noremap=true})
vim.api.nvim_set_keymap('o', 'iu', ':<c-u>lua require"treesitter-unit".select()<CR>', {noremap=true})
vim.api.nvim_set_keymap('o', 'au', ':<c-u>lua require"treesitter-unit".select(true)<CR>', {noremap=true})

