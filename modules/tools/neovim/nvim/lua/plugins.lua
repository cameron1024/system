local plugins = {
  require 'plugins.telescope',

  require 'plugins.theme.color',
  require 'plugins.theme.dressing',
  require 'plugins.theme.greeter',
  require 'plugins.theme.colorizer',
  require 'plugins.theme.reactive',

  require 'plugins.editing.surround',
  require 'plugins.editing.comment',
  require 'plugins.editing.completion',
  require 'plugins.editing.autosave',

  require 'plugins.extras.crates',

  require 'plugins.treesitter.base',

  require 'plugins.lsp.action-preview',
  require 'plugins.lsp.aerial',
  require 'plugins.lsp.base',
  require 'plugins.lsp.fidget',
  require 'plugins.lsp.trouble',
  require 'plugins.lsp.rust',

  require 'plugins.git.diffview',
  require 'plugins.git.gitsigns',

  require 'plugins.terminal.toggleterm',
  require 'plugins.terminal.termedit',
  require 'plugins.terminal.test',

  require 'plugins.lualine',

  require 'plugins.firenvim',

  require 'plugins.neotree',
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
