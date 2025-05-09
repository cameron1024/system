{config, ...}: {
  programs.nixvim = {
    diagnostic.config = {
      virtual_lines.current_line = true;
      virtual_text = false;
    };

    plugins.fidget.enable = true;
    plugins.fidget.lazyLoad.enable = true;
    plugins.fidget.lazyLoad.settings.event = ["LspAttach"];

    plugins.actions-preview.enable = true;
    plugins.actions-preview.lazyLoad.enable = true;
    plugins.actions-preview.lazyLoad.settings.keys = [
      {
        __unkeyed-1 = "gra";
        __unkeyed-2.__raw = ''
          function()
            require "actions-preview".code_actions()
          end
        '';
        mode = ["n" "v"];
      }
    ];
    plugins.actions-preview.settings = {
      backend = ["snacks"];
      snacks.layout.preset = "ivy";
    };

    plugins.lsp = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.event = ["BufReadPost" "BufNewFile"];

      keymaps.diagnostic = {
        "<C-n>" = "goto_next";
        "<C-b>" = "goto_prev";
      };
      keymaps.lspBuf = {
        "K" = "hover";
        "gd" = "definition";
        "gt" = "type_definition";
        "gi" = "implementation";
      };
      keymaps.extra = [
        {
          key = "<leader>i";
          action.__raw = ''
            function()
              local lsp = vim.lsp
              lsp.inlay_hint.enable(not lsp.inlay_hint.is_enabled())
            end
          '';
        }
        {
          key = "<leader>d";
          action.__raw = ''
            function()
              local cfg = vim.diagnostic.config()
              if cfg.virtual_lines == false then
                cfg.virtual_lines = { current_line = true }
              else
                cfg.virtual_lines = false
              end
              vim.diagnostic.config(cfg)
            end
          '';
        }
      ];

      servers.marksman.enable = true;
      servers.nixd.enable = true;
      servers.nil_ls.enable = true;
      servers.ts_ls.enable = true;
      servers.tinymist.enable = true;
      servers.bashls.enable = true;
      servers.lemminx.enable = true;

      servers.dartls.enable = true;
      servers.dartls.settings.showTodos = false;
    };
  };
}
