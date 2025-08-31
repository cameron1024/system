let
  enable = true;
  lazyLoad = {
    enable = true;
    settings.event = "InsertEnter";
  };
in {
  performance.combinePlugins.standalonePlugins = [
    "blink-cmp"
  ];

  plugins.blink-emoji = {
    inherit enable lazyLoad;
  };
  plugins.blink-cmp-git = {
    inherit enable lazyLoad;
  };

  plugins.colorful-menu = {
    inherit enable lazyLoad;
  };

  plugins.blink-cmp = {
    inherit enable lazyLoad;
    settings = {
      keymap.preset = "enter";
      keymap."<C-k>" = ["fallback"];
      keymap."<Tab>" = ["select_next" "snippet_forward" "fallback"];
      keymap."<S-Tab>" = ["select_prev" "snippet_backward" "fallback"];
      keymap."<C-c>" = ["hide" "fallback"];
      keymap."<C-space>" = ["show" "show_documentation" "hide_documentation" "fallback"];

      sources.default = [
        "lsp"
        "path"
        "buffer"
        "snippets"
        "emoji"
        # "git"
      ];
      sources.providers = {
        lsp.async = true;
        emoji = {
          module = "blink-emoji";
          name = "Emoji";
          score_offset = -30;
        };
        # git = {
        #   async = true;
        #   module = "blink-cmp-git";
        #   name = "Git";
        #   score_offset = -50;
        # };
      };

      signature.enabled = false;

      completion.ghost_text.enabled = true;

      completion.documentation.auto_show = true;
      completion.menu.draw = {
        columns.__raw = ''{ {"kind_icon"}, {"label", gap = 1 } }'';
        components.label.text.__raw = ''
          function(ctx)
            return require "colorful-menu".blink_components_text(ctx)
          end
        '';
        components.label.highlight.__raw = ''
          function(ctx)
            return require "colorful-menu".blink_components_highlight(ctx)
          end
        '';
      };
      completion.list.selection = {
        preselect = false;
        auto_insert = true;
      };
    };
  };
}
