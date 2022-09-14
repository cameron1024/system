{ pkgs, colors }:

let

  runLua = lua: ''
    lua << EOF
    ${lua}
    EOF
  '';

  includeLua = path: runLua (builtins.readFile path);
  lines-nvim = import ./custom_plugins/nvim-lines.nix { inherit pkgs; };
  git-conflict = import ./custom_plugins/git-conflict.nix { inherit pkgs; };
  flutter-tools = import ./custom_plugins/flutter-tools.nix { inherit pkgs; };
  iswap = import ./custom_plugins/iswap.nix { inherit pkgs; };
  dressing = import ./custom_plugins/dressing.nix { inherit pkgs; };

in

{
  enable = true;
  package = pkgs.neovim-unwrapped;
  vimdiffAlias = true;
  plugins = with pkgs.vimPlugins; [

    # cache require calls, startup optimization
    impatient-nvim

    # git stuff
    vim-fugitive # general git utilities
    vim-gitgutter # +/- sign in signcolumn when adding/removing lines
    git-blame-nvim # blame on cursorline
    git-conflict # conflict resolution plugin

    # LSP
    nvim-lspconfig # enable builtin LSP client
    aerial-nvim # outline view
    trouble-nvim # errors/diagnostic view

    # completions
    nvim-cmp
    cmp-nvim-lsp
    cmp-path
    cmp-buffer
    cmp-vsnip
    cmp-emoji
    vim-vsnip

    # treesitter
    nvim-treesitter
    nvim-treesitter-textobjects
    nvim-treesitter-context # keep current function signature at the top of the buffer
    iswap

    # other shit 
    webapi-vim
    mini-nvim # a bunch of cool tools
    vim-rooter # cd into the root of a git directory
    vim-auto-save # uh, autosave...
    nvim-tree-lua # FS viewer
    vim-repeat # dot repeat more commands
    vim-surround # utilities for "surround" characters
    nvim-autopairs
    vim-test

    # UI stuff
    nvim-base16 # colorscheme
    lualine-nvim # bottom bar
    nvim-web-devicons # extra icons
    fidget-nvim # LSP loading indicator
    nvim-colorizer-lua # highlight colors like this: #123456
    lines-nvim # better LSP diagnostics
    toggleterm-nvim
    dressing # nicer looking `vim.ui` stuff


    # telescope
    telescope-nvim # cool fuzzy finder + UI

    # rust
    unstable.vimPlugins.rust-tools-nvim
    crates-nvim
    rust-vim

    # dart
    unstable.vimPlugins.flutter-tools-nvim
  ];

  extraConfig = ''

    lua require('impatient')

    
    ${includeLua ./lua/optimizations.lua}
    ${includeLua ./lua/settings.lua}
    ${includeLua ./lua/keybinds.lua}
    ${includeLua ./lua/lsp.lua}
    ${includeLua ./lua/git.lua}
    ${includeLua ./lua/mini.lua}
    ${includeLua ./lua/setup_telescope.lua}
    ${includeLua ./lua/rust.lua}

    if executable("rg")
      set grepprg=rg\ --vimgrep\ --smart-case\ --hidden
      set grepformat=%f:%l:%c:%m
    endif

    let test#rust#cargotest#options = '--all-features'
    let test#neovim#term_position = "right"

    let g:auto_save = 1

    lua << EOF
    local colors = {
      base00 = "${colors.nvim.base00}",
      base01 = "${colors.nvim.base01}",
      base02 = "${colors.nvim.base02}",
      base03 = "${colors.nvim.base03}",
      base04 = "${colors.nvim.base04}",
      base05 = "${colors.nvim.base05}",
      base06 = "${colors.nvim.base06}",
      base07 = "${colors.nvim.base07}",
      base08 = "${colors.nvim.base08}",
      base09 = "${colors.nvim.base09}",
      base0A = "${colors.nvim.base0A}",
      base0B = "${colors.nvim.base0B}",
      base0C = "${colors.nvim.base0C}",
      base0D = "${colors.nvim.base0D}",
      base0E = "${colors.nvim.base0E}",
      base0F = "${colors.nvim.base0F}",
    };
    require 'base16-colorscheme'.setup(colors)

    ${builtins.readFile ./lua/ui.lua}
    EOF
  '';

}
