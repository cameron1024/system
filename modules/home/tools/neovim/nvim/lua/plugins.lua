local plugins = {
  require 'plugins.editing.autosave',
  require 'plugins.editing.comment',
  require 'plugins.editing.dial',
  require 'plugins.editing.hardtime',
  require 'plugins.editing.oil',
  require 'plugins.editing.maximize',
  require 'plugins.editing.surround',
  require 'plugins.editing.silicon',
  require 'plugins.editing.tmux-nagivator',
  require 'plugins.editing.todo-comments',

  require 'plugins.firenvim',

  require 'plugins.git.diffview',
  require 'plugins.git.octo',
  require 'plugins.git.gitsigns',
  require 'plugins.git.fugit',

  require 'plugins.lsp.actions-preview',
  require 'plugins.lsp.base',
  require 'plugins.lsp.cmp',
  require 'plugins.lsp.conform',
  require 'plugins.lsp.crates',
  require 'plugins.lsp.overseer',
  require 'plugins.lsp.rust',
  require 'plugins.lsp.trouble',
  require 'plugins.lsp.typescript',

  require 'plugins.lualine',

  require 'plugins.luarocks',

  require 'plugins.neotree',

  require 'plugins.notes.neorg',

  require 'plugins.telescope',

  require 'plugins.terminal.toggleterm',
  require 'plugins.terminal.termedit',

  require 'plugins.theme.base',
  require 'plugins.theme.noice',
  require 'plugins.theme.greeter',
  require 'plugins.theme.twilight',

  require 'plugins.treesitter.aerial',
  require 'plugins.treesitter.base',
  require 'plugins.treesitter.wildfire',
  require 'plugins.treesitter.context',
}

require 'lazy'.setup {
  spec = plugins,
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "zipPlugin",
      },
    },
  },
}
