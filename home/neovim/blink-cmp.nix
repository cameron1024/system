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
        };
        git = {
          module = "blink-cmp-git";
          name = "Git";
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
