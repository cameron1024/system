local plugins = {
  require 'plugins.debug.dap-ui',

  require 'plugins.editing.autosave',
  require 'plugins.editing.autopairs',
  require 'plugins.editing.debug-print',
  require 'plugins.editing.diagram',
  require 'plugins.editing.paste-image',
  require 'plugins.editing.precognition',
  require 'plugins.editing.surround',
  require 'plugins.editing.tmux-navigator',
  require 'plugins.editing.quicker',
  require 'plugins.editing.ufo',
  require 'plugins.editing.zen',

  require 'plugins.files.image',
  require 'plugins.files.oil',

  require 'plugins.git.diffview',
  require 'plugins.git.fugitive',
  require 'plugins.git.gitsigns',
  require 'plugins.git.gh',
  require 'plugins.git.octo',

  require 'plugins.lsp.actions-preview',
  require 'plugins.lsp.blink',
  require 'plugins.lsp.formatter',
  require 'plugins.lsp.lsp',
  require 'plugins.lsp.refjump',
  require 'plugins.lsp.rename',

  require 'plugins.lang.markdown',
  require 'plugins.lang.rust',
  require 'plugins.lang.typst',

  require 'plugins.theme.everforest',
  require 'plugins.theme.twilight',
  require 'plugins.theme.showkeys',

  require 'plugins.toys.feed',

  require 'plugins.treesitter.base',
  require 'plugins.treesitter.treeclimber',
  require 'plugins.treesitter.wildfire',

  require 'plugins.term.toggleterm',

  require 'plugins.neotest',

  require 'plugins.lualine',
  require 'plugins.telescope',
  require 'plugins.trouble',

}


local config = {
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

local extra = {
  defaults = { lazy = true },
}

require 'lazy'.setup(config, extra)
