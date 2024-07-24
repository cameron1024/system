local plugins = {

  require 'plugins.lsp.base',
  require 'plugins.lsp.rust',

  require 'plugins.telescope.base',

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
