{pkgs, ...}: {
  extraPlugins = with pkgs.vimPlugins; [treesitter-modules-nvim];
  extraConfigLua = ''
    local keymap = require "lz.n".keymap {
      "treesitter-modules",
      before = function()
        require "lz.n".trigger_load "nvim-treesitter"
      end,
      after = function()
        require "treesitter-modules".setup {
          fold = { enable = true },
          highlight = { enable = true },
          indent = { enable = true },
          incremental_selection = { enable = true }, 
        }
      end,
    }

    keymap.set('n', '<CR>', function() require "treesitter-modules".init_selection() end)
    keymap.set('x', '<CR>', function() require "treesitter-modules".node_incremental() end)
    keymap.set('x', '<Backspace>', function() require "treesitter-modules".node_decremental() end)
  '';
}
