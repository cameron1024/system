local plugins = {
  require 'plugins.editing.autosave',
  require 'plugins.editing.comment',
  require 'plugins.editing.flash',
  require 'plugins.editing.image-view',
  -- require 'plugins.editing.oil',
  require 'plugins.editing.surround',
  require 'plugins.editing.tmux-nagivator',
  require 'plugins.editing.todo-comments',

  require 'plugins.firenvim',

  require 'plugins.git.diffview',
  require 'plugins.git.octo',
  require 'plugins.git.gitsigns',

  require 'plugins.lsp.base',
  require 'plugins.lsp.cmp',
  require 'plugins.lsp.rust',
  require 'plugins.lsp.trouble',
  -- require 'plugins.lsp.ui',

  require 'plugins.lualine',

  require 'plugins.neotree',

  require 'plugins.telescope',

  require 'plugins.terminal.toggleterm',
  require 'plugins.terminal.termedit',

  require 'plugins.theme.base',
  require 'plugins.theme.noice',
  require 'plugins.theme.greeter',
  require 'plugins.theme.twilight',

  require 'plugins.treesitter.base',
  require 'plugins.treesitter.wildfire',
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
        "tutor",
        "zipPlugin",
      },
    },
  },
}
