{pkgs, ...}: let
  package = {
    vimUtils,
    fetchFromGitHub,
    ...
  }:
    vimUtils.buildVimPlugin {
      name = "nvim-0x0";
      src = fetchFromGitHub {
        owner = "LionyxML";
        repo = "nvim-0x0";
        rev = "2c8ec9c9a4920de729aa2de7724a46d3448df30a";
        hash = "sha256-CXv5nN9dPshAQTO4RVTNi2WKULVVR/X7WeujaRV1PLc=";
      };
    };
in {
  programs.nixvim = {
    extraPlugins = [(pkgs.callPackage package {})];
    extraConfigLua = ''
      local keymap = require 'lz.n'.keymap {
        "nvim-0x0",
        after = function()
          require 'nvim-0x0'.setup {
            use_default_keymaps = false,
          }
        end,
      }

      vim.keymap.set(
        'n',
        '<leader>0f',
        function() require("nvim-0x0").upload_current_file() end,
        { desc = "Upload current file" }
      )
      vim.keymap.set(
        'n',
        '<leader>uF',
        function()
          require("nvim-0x0").upload_current_file({ append_filename = true })
        end,
        { desc = "Upload current file (preserve filename)" }
      )
      vim.keymap.set(
        'v',
        '<leader>0s',
        function() require("nvim-0x0").upload_selection() end,
        { desc = "Upload selection" }
      )
      vim.keymap.set(
        'n',
        '<leader>0y',
        function() require("nvim-0x0").upload_yank() end,
        { desc = "Upload yank" }
      )
      vim.keymap.set(
        'n',
        '<leader>0o',
        function() require("nvim-0x0").upload_oil_file() end,
        { desc = "Upload oil.nvim file" }
      )
      vim.keymap.set(
        'n',
        '<leader>0O',
        function() require("nvim-0x0").upload_oil_file({ append_filename = true }) end,
        { desc = "Upload oil.nvim file (preserve filename)" }
      )
    '';
  };
}
