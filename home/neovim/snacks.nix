{
  env."SNACKS_KITTY" = "true";

  plugins.snacks = {
    enable = true;
    lazyLoad = {
      enable = true;
      settings.ft = ["markdown" "typst" "png"]; # for images
      settings.keys = [
        # === Searching ===

        {
          desc = "Files";
          __unkeyed-1 = "<leader>n";
          __unkeyed-2.__raw = ''
            function() Snacks.picker.files { hidden = true, } end
          '';
        }
        {
          desc = "Files Cword";
          __unkeyed-1 = "<leader>N";
          __unkeyed-2.__raw = ''
            function() Snacks.picker.files { hidden = true, search = vim.fn.expand "<cword>" } end
          '';
        }
        {
          desc = "Grep";
          __unkeyed-1 = "<leader>f";
          __unkeyed-2.__raw = ''
            function() Snacks.picker.grep { hidden = true } end
          '';
        }
        {
          desc = "Grep Cword";
          __unkeyed-1 = "<leader>F";
          __unkeyed-2.__raw = ''
            function() Snacks.picker.grep { hidden = true, search = vim.fn.expand "<cword>" } end
          '';
        }
        {
          desc = "Marks";
          __unkeyed-1 = "<leader>m";
          __unkeyed-2.__raw = ''
            function() Snacks.picker.marks() end
          '';
        }
        {
          desc = "File Picker";
          __unkeyed-1 = "<leader>p";
          __unkeyed-2.__raw = ''
            function() Snacks.picker.explorer() end
          '';
        }
        {
          desc = "Undo";
          __unkeyed-1 = "<leader>u";
          __unkeyed-2.__raw = ''
            function() Snacks.picker.undo() end
          '';
        }
        {
          desc = "Search history";
          __unkeyed-1 = "<leader>/";
          __unkeyed-2.__raw = ''
            function() Snacks.picker.search_history() end
          '';
        }
        {
          desc = "Last Picker";
          __unkeyed-1 = "<leader><leader>";
          __unkeyed-2.__raw = ''
            function() Snacks.picker.resume() end
          '';
        }
        # === Terminal ===
        {
          desc = "Toggle Terminal";
          mode = ["n" "i" "v" "t" "x"];
          __unkeyed-1 = "<C-t>";
          __unkeyed-2.__raw = ''
            function()
              Snacks.terminal.toggle(nil, {
                interactive = true,
                auto_close = true,
              })
            end
          '';
        }
        # === Jumps ===
        {
          desc = "Next reference";
          mode = ["n" "o" "x" "v"];
          __unkeyed-1 = "]r";
          __unkeyed-2.__raw = ''
            function() Snacks.words.jump(1, true) end
          '';
        }
        {
          desc = "Prev reference";
          mode = ["n" "o" "x" "v"];
          __unkeyed-1 = "[r";
          __unkeyed-2.__raw = ''
            function() Snacks.words.jump(-1, true) end
          '';
        }
      ];
    };

    settings = {
      indent.enabled = true;
      input.enabled = true;
      picker.layout = "ivy";
      notifier.enable = true;
      words.enabled = true;

      image.enable = true;
      image.math.enabled = false; # typst equations look weird
      image.convert.mermaid.__raw = ''
        function()
          local theme = vim.o.background == "light" and "neutral" or "dark"
          return { "-i", "{src}", "-o", "{file}", "-b", "#2d353b", "-t", theme, "-s", "{scale}" }
        end
      '';

      terminal.win.height = 15;
    };
  };
}
