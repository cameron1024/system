{pkgs, ...}: {
  home.packages = with pkgs; [imagemagick mermaid-cli ghostscript];
  programs.nixvim.plugins.snacks = {
    enable = true;
    lazyLoad = {
      enable = true;
      settings.ft = ["markdown" "typst"]; # for images
      settings.keys = [
        # === Searching ===

        {
          desc = "Files";
          __unkeyed-1 = "<leader>n";
          __unkeyed-2.__raw =
            /*
            lua
            */
            ''
              function() Snacks.picker.files() end
            '';
        }
        {
          desc = "Grep";
          __unkeyed-1 = "<leader>f";
          __unkeyed-2.__raw =
            /*
            lua
            */
            ''
              function() Snacks.picker.grep() end
            '';
        }
        {
          desc = "Last Picker";
          __unkeyed-1 = "<leader><leader>";
          __unkeyed-2.__raw =
            /*
            lua
            */
            ''
              function() Snacks.picker.resume() end
            '';
        }

        # === Terminal ===
        {
          desc = "Toggle Terminal";
          mode = ["n" "i" "v" "t" "x"];
          __unkeyed-1 = "<C-t>";
          __unkeyed-2.__raw =
            /*
            lua
            */
            ''
              function()
                Snacks.terminal.toggle(nil, {
                  interactive = true,
                  auto_close = true,
                })
              end
            '';
        }
      ];
    };

    settings = {
      input.enabled = true;
      picker.layout = "ivy";
      notifier.enable = true;

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
