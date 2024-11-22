local plugins = {
  require 'plugins.editing.autosave',
  require 'plugins.editing.surround',
  require 'plugins.editing.tmux-navigator',

  require 'plugins.files.oil',

  require 'plugins.lsp.lsp',
  -- require 'plugins.lsp.blink',

  require 'plugins.theme.everforest',

  require 'plugins.lualine',
  require 'plugins.telescope',
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
