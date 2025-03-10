local plugins = {
  require 'plugins.debug.dap-ui',

  require 'plugins.editing.autosave',
  require 'plugins.editing.autopairs',
  require 'plugins.editing.debug-print',
  -- require 'plugins.editing.foldtext',
  require 'plugins.editing.hlslens',
  require 'plugins.editing.hover',
  -- require 'plugins.editing.diagram',
  -- require 'plugins.editing.paste-image',
  require 'plugins.editing.precognition',
  require 'plugins.editing.surround',
  require 'plugins.editing.tmux-navigator',
  require 'plugins.editing.quicker',
  require 'plugins.editing.ufo',
  require 'plugins.editing.zen',

  -- require 'plugins.files.image',
  require 'plugins.files.oil',

  require 'plugins.git.diffview',
  require 'plugins.git.fugitive',
  require 'plugins.git.gitsigns',
  require 'plugins.git.gh',
  require 'plugins.git.octo',
  -- require 'plugins.git.vgit',

  require 'plugins.lsp.ai',
  require 'plugins.lsp.actions-preview',
  require 'plugins.lsp.blink',
  require 'plugins.lsp.formatter',
  require 'plugins.lsp.inline-diagnostic',
  require 'plugins.lsp.lsp',
  require 'plugins.lsp.namu',
  require 'plugins.lsp.refjump',
  require 'plugins.lsp.rename',

  require 'plugins.lang.cedar',
  require 'plugins.lang.csv',
  require 'plugins.lang.flutter',
  require 'plugins.lang.lean',
  require 'plugins.lang.markdown',
  require 'plugins.lang.ron',
  require 'plugins.lang.rust',
  require 'plugins.lang.typst',

  require 'plugins.telescope.emoji',
  require 'plugins.telescope.base',
  require 'plugins.telescope.glyph',
  require 'plugins.telescope.symbols',

  require 'plugins.theme.colorizer',
  require 'plugins.theme.everforest',
  require 'plugins.theme.twilight',
  require 'plugins.theme.showkeys',

  require 'plugins.toys.apm',
  require 'plugins.toys.doing',
  require 'plugins.toys.feed',
  require 'plugins.toys.hardtime',
  require 'plugins.toys.typr',

  require 'plugins.treesitter.base',
  require 'plugins.treesitter.commentstring',
  require 'plugins.treesitter.language-injection',
  require 'plugins.treesitter.treeclimber',
  require 'plugins.treesitter.treesj',
  require 'plugins.treesitter.wildfire',

  require 'plugins.term.toggleterm',

  require 'plugins.firenvim',
  require 'plugins.lualine',
  require 'plugins.neotest',
  require 'plugins.neotree',
  require 'plugins.trouble',
  require 'plugins.patterns',
  require 'plugins.zettel',
  -- require 'plugins.snacks',
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
