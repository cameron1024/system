local plugins = {
  -- require 'plugins.editing.autosave',
  require 'plugins.editing.comment',
  require 'plugins.editing.colorizer',
  require 'plugins.editing.dial',
  require 'plugins.editing.firestore-rules',
  require 'plugins.editing.hardtime',
  -- require 'plugins.editing.hlslens',
  -- require 'plugins.editing.hlchunk',
  require 'plugins.editing.oil',
  require 'plugins.editing.maximize',
  require 'plugins.editing.markdown',
  require 'plugins.editing.minty',
  require 'plugins.editing.surround',
  require 'plugins.editing.silicon',
  require 'plugins.editing.tmux-nagivator',
  require 'plugins.editing.todo-comments',
  require 'plugins.editing.typst',
  require 'plugins.editing.ufo',
  require 'plugins.editing.zoxide',

  require 'plugins.debug.dap',
  require 'plugins.debug.dap-ui',

  {
    "glacambre/firenvim",
    build = ":call firenvim#install(0)",
  },

  require 'plugins.git.diffview',
  require 'plugins.git.flog',
  require 'plugins.git.octo',
  require 'plugins.git.gitsigns',
  -- require 'plugins.git.fugit',

  require 'plugins.lsp.actions-preview',
  require 'plugins.lsp.base',
  require 'plugins.lsp.cmp',
  -- require 'plugins.lsp.blink',  -- cmp alternative
  require 'plugins.lsp.conform',
  require 'plugins.lsp.crates',
  require 'plugins.lsp.flutter',
  -- require 'plugins.lsp.overseer',
  require 'plugins.lsp.rust',
  require 'plugins.lsp.trouble',
  require 'plugins.lsp.typescript',

  require 'plugins.lualine',

  require 'plugins.luarocks',

  require 'plugins.neotree',

  -- require 'plugins.notes.neorg',
  require 'plugins.notes.telekasten',

  require 'plugins.telescope',

  require 'plugins.test.neotest',

  require 'plugins.terminal.toggleterm',
  require 'plugins.terminal.termedit',

  -- require 'plugins.theme.catppuccin',
  require 'plugins.theme.noice',
  -- require 'plugins.theme.gruvbox',
  require 'plugins.theme.everforest',
  require 'plugins.theme.twilight',

  require 'plugins.treesitter.aerial',
  require 'plugins.treesitter.base',
  require 'plugins.treesitter.wildfire',
  require 'plugins.treesitter.context',
  require 'plugins.treesitter.ssr',
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
