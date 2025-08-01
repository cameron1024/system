{pkgs, ...}: {
  extraPlugins = [pkgs.vimPlugins.treewalker-nvim];
  extraConfigLua = ''
    local keymap = require "lz.n".keymap {
      "treewalker.nvim",
      cmd = "Treewalker",
      before = function()
        require "lz.n".trigger_load "nvim-treesitter"
      end,
    }

    keymap.set({ 'n', 'v', 'o' }, '<M-k>', '<cmd>Treewalker Up<cr>', { silent = true })
    keymap.set({ 'n', 'v', 'o' }, '<M-j>', '<cmd>Treewalker Down<cr>', { silent = true })
    keymap.set({ 'n', 'v', 'o' }, '<M-h>', '<cmd>Treewalker Left<cr>', { silent = true })
    keymap.set({ 'n', 'v', 'o' }, '<M-l>', '<cmd>Treewalker Right<cr>', { silent = true })

    keymap.set('n', '<M-S-k>', '<cmd>Treewalker SwapUp<cr>', { silent = true })
    keymap.set('n', '<M-S-j>', '<cmd>Treewalker SwapDown<cr>', { silent = true })
    keymap.set('n', '<M-S-h>', '<cmd>Treewalker SwapLeft<cr>', { silent = true })
    keymap.set('n', '<M-S-l>', '<cmd>Treewalker SwapRight<cr>', { silent = true })
  '';
}
