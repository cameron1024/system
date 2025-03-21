local map = function(mode, key, action, options)
  options = options or { noremap = true, silent = true };
  vim.keymap.set(mode, key, action, options)
end

-- saving and closing
map('n', '<leader>q', ':x<CR>')
map('n', '<leader>Q', ':wqa!<CR>')
map('n', '<leader>w', ':wa<CR>')

-- window management
map('n', '<leader><Tab>', '<C-^>')
map('n', '<C-v>', ':vs<CR>')
map('n', '<C-x>', ':sp<CR>')

-- remap <C-v> for block select mode
map('n', '<leader>v', '<C-v>')

-- ctrl + hjkl to switch panes
-- map('n', '<C-k>', '<C-w><Up>')
-- map('n', '<C-j>', '<C-w><Down>')
-- map('n', '<C-h>', '<C-w><Left>')
-- map('n', '<C-l>', '<C-w><Right>')

-- ctrl + hjkl to move in insert mode
map({ 'i', 'v', 't' }, '<C-k>', '<Up>')
map({ 'i', 'v', 't' }, '<C-j>', '<Down>')
map({ 'i', 'v', 't' }, '<C-h>', '<Left>')
map({ 'i', 'v', 't' }, '<C-l>', '<Right>')

-- when pasting, don't update the register
map("x", "p", [["_dP]])

-- move to start/end of line
map({ "n", "o", "x", "v" }, "H", "^")
map({ "n", "o", "x", "v" }, "L", "g_")

map("n", "<leader>ww", function() vim.wo.wrap = not vim.wo.wrap end)

map("n", "<esc>", ":nohl<cr>")

-- terminal sanity
map('t', '<ESC>', '<C-\\><C-n>')
-- map('t', '<C-h>', [[<Cmd>wincmd h<CR>]])
-- map('t', '<C-j>', [[<Cmd>wincmd j<CR>]])
-- map('t', '<C-k>', [[<Cmd>wincmd k<CR>]])
-- map('t', '<C-l>', [[<Cmd>wincmd l<CR>]])

-- indenting selections without deselecting
map('v', '<', '<gv')
map('v', '>', '>gv')

-- yank current file path
map('n', '<leader>cf', ':let @+ = expand("%")<CR>')
map('n', '<leader>cp', ':let @+ = expand("%:p")<CR>')

--duplicate selection
map('v', '<C-d>', [[y'>pgv]])

-- make * stay on the same entry
map('n', '*', '*N')

-- ctrl + enter to toggle fold
map({ 'n', 'v' }, '<C-CR>', 'za')

map('i', '<C-CR>', '<C-o>o')

-- stop any in-progress snippet when exiting insert mode
map({ 'i', 's' }, '<Esc>', function()
  vim.snippet.stop();
  return '<Esc>'
end, { expr = true })

local function toggle_conceal()
  if vim.o.conceallevel == 0 then
    vim.o.conceallevel = 2
  else
    vim.o.conceallevel = 0
  end
end

map("n", "<leader>cc", toggle_conceal)

-- format a comment
map("n", "<C-f>", "gwgc")

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function() vim.snippet.stop() end
})
