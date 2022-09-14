-- local fn = vim.fn
-- local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
-- print("install_path: " .. install_path)
-- if fn.empty(fn.glob(install_path)) > 0 then
--     packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
--     download_result = fn.system({'ls', '-l', install_path})
--     print("download_result: " .. download_result)
-- end

require 'packer'.startup(function()
local use = use

-- bootstrap self
use 'wbthomason/packer.nvim'

-- performance optimizations
use 'lewis6991/impatient.nvim'

-- utilities
use { 'echasnovski/mini.nvim', branch = 'stable' }
use { 'nvim-telescope/telescope.nvim', requires = { {'nvim-lua/plenary.nvim'} } }
use { 'vim-test/vim-test' }
use '907th/vim-auto-save'
use 'airblade/vim-rooter'
use { 'kyazdani42/nvim-tree.lua', requires = { 'kyazdani42/nvim-web-devicons' } }
use 'tpope/vim-surround'

-- git
use 'tpope/vim-fugitive'
use 'airblade/vim-gitgutter'
use 'f-person/git-blame.nvim'
use 'akinsho/git-conflict.nvim'

-- lsp
use 'neovim/nvim-lspconfig'
use 'williamboman/nvim-lsp-installer'
use 'j-hui/fidget.nvim'
use 'stevearc/aerial.nvim'
use { "folke/trouble.nvim", requires = "kyazdani42/nvim-web-devicons", }

-- completion
use 'hrsh7th/nvim-cmp'
use 'hrsh7th/cmp-nvim-lsp'
use 'hrsh7th/cmp-path'
use 'hrsh7th/cmp-buffer'
use 'hrsh7th/cmp-vsnip'
use 'hrsh7th/cmp-emoji'
use 'hrsh7th/vim-vsnip'

-- treesitter
use 'nvim-treesitter/nvim-treesitter'
use 'nvim-treesitter/nvim-treesitter-textobjects'


-- UI
use 'nvim-lualine/lualine.nvim'
use 'RRethy/nvim-base16'

-- rust
use 'simrat39/rust-tools.nvim'
use {
    'saecki/crates.nvim',
    tag = 'v0.1.0',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function()
        require('crates').setup()
    end,
}

-- dart/flutter
use 'akinsho/flutter-tools.nvim'
end)
