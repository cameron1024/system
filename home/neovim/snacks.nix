let
  binding = {
    key,
    action,
    desc ? null,
    mode ? null,
  }: {
    inherit desc mode;
    __unkeyed-1 = key;
    __unkeyed-2 = action;
  };
in {
  env."SNACKS_KITTY" = "true";

  plugins.snacks = {
    enable = true;
    lazyLoad = {
      enable = true;
      settings.ft = ["markdown" "typst" "png"]; # for images
      settings.keys = map binding [
        # === Searching ===
        {
          desc = "Files";
          key = "<leader>n";
          action.__raw = "function() Snacks.picker.files { hidden = true } end";
        }
        {
          desc = "Files Cword";
          key = "<leader>N";
          action.__raw = ''
            function()
              Snacks.picker.files {
                hidden = true,
                search = vim.fn.expand "<cword>",
              }
            end
          '';
        }
        {
          desc = "Grep";
          key = "<leader>f";
          action.__raw = "function() Snacks.picker.grep { hidden = true } end";
        }
        {
          desc = "Grep Cword";
          key = "<leader>F";
          action.__raw = ''
            function()
              Snacks.picker.grep {
                hidden = true,
                search = vim.fn.expand "<cword>",
              }
            end
          '';
        }

        # === LSP ===
        {
          desc = "LSP Definitions";
          key = "gd";
          action.__raw = "function() Snacks.picker.lsp_definitions() end";
        }
        {
          desc = "LSP Type Definition";
          key = "gt";
          action.__raw = "function() Snacks.picker.lsp_type_definitions() end";
        }
        {
          desc = "LSP References";
          key = "grr";
          action.__raw = "function() Snacks.picker.lsp_references() end";
        }
        {
          desc = "LSP Implementations";
          key = "gi";
          action.__raw = "function() Snacks.picker.lsp_implementations() end";
        }

        {
          desc = "Marks";
          key = "<leader>m";
          action.__raw = "function() Snacks.picker.marks() end";
        }
        {
          desc = "File Picker";
          key = "<leader>p";
          action.__raw = "function() Snacks.picker.explorer() end";
        }
        {
          desc = "Search history";
          key = "<leader>/";
          action.__raw = ''
            function() Snacks.picker.search_history() end
          '';
        }
        {
          desc = "Diagnostics";
          key = "<leader>d";
          action.__raw = ''
            function() Snacks.picker.diagnostics() end
          '';
        }
        {
          desc = "Zoxide";
          key = "<leader>z";
          action.__raw = ''
            function() Snacks.picker.zoxide() end
          '';
        }
        {
          desc = "Last Picker";
          key = "<leader><leader>";
          action.__raw = ''
            function() Snacks.picker.resume() end
          '';
        }
        # === Terminal ===
        {
          desc = "Toggle Terminal";
          mode = ["n" "i" "v" "t" "x"];
          key = "<C-t>";
          action.__raw = ''
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
          key = "]r";
          action.__raw = ''
            function() Snacks.words.jump(1, true) end
          '';
        }
        {
          desc = "Prev reference";
          mode = ["n" "o" "x" "v"];
          key = "[r";
          action.__raw = ''
            function() Snacks.words.jump(-1, true) end
          '';
        }
      ];
    };
    settings = {
      indent.enabled = true;
      input.enabled = true;
      picker.layout = "ivy";
      picker.win.input.keys."<a-p>" = false;
      picker.win.input.keys."<a-k>".__raw = ''{ "toggle_preview", mode = { "i", "n" } }'';
      picker.win.input.keys."<c-r><c-f>".__raw = ''{ "insert_file", mode = "i" }'';
      notifier.enable = true;
      words.enabled = true;
      quickfile.enabled = true;
      statuscolumn.enabled = true;

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
