{
  plugins.diffview.enable = true;
  plugins.diffview.enhancedDiffHl = true;

  plugins.gitsigns = {
    enable = true;
    lazyLoad.enable = true;
    lazyLoad.settings.event = "BufRead";
    lazyLoad.settings.keys = [
      {
        __unkeyed-1 = "<leader>hs";
        __unkeyed-2.__raw = "function() require 'gitsigns'.stage_hunk() end";
        mode = ["n"];
      }
      {
        __unkeyed-1 = "<leader>hr";
        __unkeyed-2.__raw = "function() require 'gitsigns'.reset_hunk() end";
        mode = ["n"];
      }
      {
        __unkeyed-1 = "<leader>hs";
        __unkeyed-2.__raw = ''
          function()
            require 'gitsigns'.stage_hunk { vim.fn.line('.'), vim.fn.line('v') }
          end
        '';
        mode = ["v"];
      }
      {
        __unkeyed-1 = "<leader>hr";
        __unkeyed-2.__raw = ''
          function()
            require 'gitsigns'.reset_hunk { vim.fn.line('.'), vim.fn.line('v') }
          end
        '';
        mode = ["v"];
      }
      {
        __unkeyed-1 = "<leader>hp";
        __unkeyed-2.__raw = ''
          function() require 'gitsigns'.preview_hunk() end
        '';
      }
      {
        __unkeyed-1 = "]c";
        __unkeyed-2.__raw = ''
          function()
            if vim.wo.diff then
              vim.cmd.normal { ']c', bang = true }
            else
              require 'gitsigns'.nav_hunk 'next'
            end
          end
        '';
      }
      {
        __unkeyed-1 = "[c";
        __unkeyed-2.__raw = ''
          function()
            if vim.wo.diff then
              vim.cmd.normal { '[c', bang = true }
            else
              require 'gitsigns'.nav_hunk 'prev'
            end
          end
        '';
      }
      {
        __unkeyed-1 = "ih";
        __unkeyed-2.__raw = ''
          function() require 'gitsigns'.select_hunk() end
        '';
        mode = ["o" "x"];
      }
    ];

    settings = {
      current_line_blame = true;
      current_line_blame_opts = {
        virt_text = true;
        virt_text_pos = "eol";
      };
    };
  };

  # plugins.octo = {
  #   enable = true;
  #   lazyLoad.enable = true;
  #   lazyLoad.settings.cmd = "Octo";
  # };

  plugins.fugitive.enable = true;

  plugins.hunk = {
    enable = true;
    lazyLoad.enable = true;
    lazyLoad.settings.cmd = "DiffEditor";
  };
}
