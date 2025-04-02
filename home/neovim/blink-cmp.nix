let
  enable = true;
  lazyLoad = {
    enable = true;
    settings.event = "InsertEnter";
  };
in {
  programs.nixvim.plugins.blink-emoji = {
    inherit enable lazyLoad;
  };
  programs.nixvim.plugins.blink-cmp-git = {
    inherit enable lazyLoad;
  };

  programs.nixvim.plugins.blink-cmp = {
    inherit enable lazyLoad;
    settings = {
      keymap.preset = "enter";
      keymap."<Tab>" = ["select_next" "snippet_forward" "fallback"];
      keymap."<S-Tab>" = ["select_prev" "snippet_backward" "fallback"];
      keymap."<C-c>" = ["hide" "fallback"];
      keymap."<C-space>" = ["show" "show_documentation" "hide_documentation" "fallback"];

      sources.default = ["lsp" "path" "buffer" "snippets" "emoji" "git"];
      sources.providers = {
        lsp.async = true;
        emoji = {
          module = "blink-emoji";
          name = "Emoji";
          score_offset = -30;
          enabled.__raw = ''
            function()
              local node = vim.treesitter.get_node()
              if node then
                  if string.find(node:type(), "comment") == nil then
                    return true
                  end

                  if string.find(node:type(), "string") == nil then
                    return true
                  end

                  return false
              else
                return true
              end
            end
          '';
        };
        git = {
          async = true;
          module = "blink-cmp-git";
          name = "Git";
          score_offset = -15;
          enabled.__raw = ''
            function()
              if vim.tbl_contains({ 'octo', 'gitcommit', 'markdown' }, vim.bo.filetype) then
                return true
              end

              local node = vim.treesitter.get_node()
              if node then
                 return not (string.find(node:type(), "comment") == nil)
              else
                return true
              end
            end
          '';
        };
      };

      signature.enabled = true;
      completion.documentation.auto_show = true;
      completion.ghost_text.enabled = true;
      completion.list.selection = {
        preselect = false;
        auto_insert = true;
      };
    };
  };
}
